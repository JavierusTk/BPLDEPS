program BPLDeps;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Winapi.Windows;

type
  TDependencyList = TDictionary<string, string>; // Name -> Path (empty if not found)

function RvaToFileOffset(Stream: TStream; NTHeaders: PImageNtHeaders; NTHeadersOffset: DWORD; RVA: DWORD): DWORD; forward;

procedure ShowUsage;
begin
  WriteLn('BPLDeps - BPL Dependency Analyzer');
  WriteLn('Usage: BPLDeps <file.bpl> [options]');
  WriteLn('');
  WriteLn('Options:');
  WriteLn('  -r    Show recursive dependencies (default)');
  WriteLn('  -d    Show only direct dependencies');
  WriteLn('  -t    Show as tree');
  WriteLn('  -v    Verbose mode (show paths and summary)');
  WriteLn('');
  WriteLn('Example: BPLDeps rtl290.bpl -v');
end;

function GetBplPath(const FileName: string): string;
var
  SearchPaths: TArray<string>;
  Path: string;
begin
  // If already has full path and exists, expand to complete path
  if FileExists(FileName) then
    Exit(ExpandFileName(FileName));

  // Search in common directories
  SearchPaths := [
    ExtractFilePath(ParamStr(0)),
    GetCurrentDir,
    'C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\',
    'C:\Program Files (x86)\Embarcadero\Studio\23.0\bin64\',
    GetEnvironmentVariable('PATH')
  ];

  for Path in SearchPaths do
  begin
    if Path.IsEmpty then Continue;
    Result := IncludeTrailingPathDelimiter(Path) + FileName;
    if FileExists(Result) then
      Exit(ExpandFileName(Result)); // Expand to complete path
  end;

  Result := ''; // Return empty if not found
end;

procedure GetDirectDependencies(const BplPath: string; Dependencies: TStrings);
var
  Stream: TFileStream;
  DosHeader: TImageDosHeader;
  NTHeaders: TImageNtHeaders;
  ImportDir: TImageDataDirectory;
  ImportDesc: TImageImportDescriptor;
  ImportRVA: DWORD;
  BaseAddr: Int64;
  NameRVA: DWORD;
  DllName: array[0..MAX_PATH] of AnsiChar;
  DllNameStr: string;
  BytesRead: Integer;
  NTHeadersOffset: DWORD;
begin
  Stream := TFileStream.Create(BplPath, fmOpenRead or fmShareDenyNone);
  try
    // Read DOS header
    Stream.ReadBuffer(DosHeader, SizeOf(DosHeader));
    if DosHeader.e_magic <> IMAGE_DOS_SIGNATURE then
      raise Exception.Create('Invalid DOS signature');

    // Go to NT headers
    NTHeadersOffset := DosHeader._lfanew;
    Stream.Position := NTHeadersOffset;
    Stream.ReadBuffer(NTHeaders, SizeOf(NTHeaders));
    if NTHeaders.Signature <> IMAGE_NT_SIGNATURE then
      raise Exception.Create('Invalid NT signature');

    // Get Import Directory
    ImportDir := NTHeaders.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT];
    if ImportDir.VirtualAddress = 0 then
      Exit; // No imports

    // Calculate real offset of Import Descriptor
    ImportRVA := RvaToFileOffset(Stream, @NTHeaders, NTHeadersOffset, ImportDir.VirtualAddress);
    if ImportRVA = 0 then
      Exit;

    Stream.Position := ImportRVA;

    // Read each Import Descriptor
    while True do
    begin
      BytesRead := Stream.Read(ImportDesc, SizeOf(ImportDesc));
      if (BytesRead < SizeOf(ImportDesc)) or (ImportDesc.Name = 0) then
        Break;

      // Read DLL name
      NameRVA := RvaToFileOffset(Stream, @NTHeaders, NTHeadersOffset, ImportDesc.Name);
      if NameRVA > 0 then
      begin
        BaseAddr := Stream.Position;
        Stream.Position := NameRVA;
        FillChar(DllName, SizeOf(DllName), 0);
        Stream.Read(DllName[0], SizeOf(DllName) - 1);
        Stream.Position := BaseAddr;

        DllNameStr := string(AnsiString(DllName));

        // Only include .bpl files
        if SameText(ExtractFileExt(DllNameStr), '.bpl') then
          Dependencies.Add(ChangeFileExt(ExtractFileName(DllNameStr), ''));
      end;
    end;
  finally
    Stream.Free;
  end;
end;

function RvaToFileOffset(Stream: TStream; NTHeaders: PImageNtHeaders; NTHeadersOffset: DWORD; RVA: DWORD): DWORD;
var
  SectionHeader: TImageSectionHeader;
  I: Integer;
  SectionOffset: Int64;
begin
  Result := 0;

  // Save current position
  SectionOffset := Stream.Position;

  // Sections start after NT headers
  Stream.Position := NTHeadersOffset + SizeOf(DWORD) + SizeOf(TImageFileHeader) + NTHeaders.FileHeader.SizeOfOptionalHeader;

  // Find which section contains the RVA
  for I := 0 to NTHeaders.FileHeader.NumberOfSections - 1 do
  begin
    Stream.ReadBuffer(SectionHeader, SizeOf(SectionHeader));

    if (RVA >= SectionHeader.VirtualAddress) and
       (RVA < SectionHeader.VirtualAddress + SectionHeader.SizeOfRawData) then
    begin
      Result := RVA - SectionHeader.VirtualAddress + SectionHeader.PointerToRawData;
      Break;
    end;
  end;

  // Restore position
  Stream.Position := SectionOffset;
end;

procedure GetAllDependencies(const BplPath: string; AllDeps: TDependencyList;
  Level: Integer = 0; ShowTree: Boolean = False);
var
  DirectDeps: TStringList;
  DepName: string;
  DepPath: string;
  Indent: string;
begin
  DirectDeps := TStringList.Create;
  try
    GetDirectDependencies(BplPath, DirectDeps);

    if ShowTree then
      Indent := StringOfChar(' ', Level * 2);

    for DepName in DirectDeps do
    begin
      if not AllDeps.ContainsKey(DepName) then
      begin
        // Recursively get dependencies of this BPL
        DepPath := GetBplPath(DepName + '.bpl');

        if not DepPath.IsEmpty then
        begin
          AllDeps.Add(DepName, DepPath);

          if ShowTree then
            WriteLn(Indent + DepName + '.bpl');

          try
            GetAllDependencies(DepPath, AllDeps, Level + 1, ShowTree);
          except
            on E: Exception do
              if ShowTree then
                WriteLn(Indent + '  [Error: ' + E.Message + ']');
          end;
        end
        else
        begin
          AllDeps.Add(DepName, ''); // Empty path = not found

          if ShowTree then
          begin
            WriteLn(Indent + DepName + '.bpl');
            WriteLn(Indent + '  [Not found]');
          end;
        end;
      end;
    end;
  finally
    DirectDeps.Free;
  end;
end;

procedure ProcessBpl(const BplFileName: string; Recursive: Boolean; ShowTree: Boolean; Verbose: Boolean);
var
  BplPath: string;
  AllDeps: TDependencyList;
  DirectDeps: TStringList;
  DepName: string;
  DepList: TArray<string>;
  DepPath: string;
  Found, NotFound: Integer;
begin
  BplPath := GetBplPath(BplFileName);

  if BplPath.IsEmpty then
  begin
    WriteLn('Error: File not found: ', BplFileName);
    Exit;
  end;

  WriteLn('Analyzing: ', ExtractFileName(BplPath));
  WriteLn('Full path: ', BplPath);
  WriteLn('');

  if Recursive then
  begin
    AllDeps := TDependencyList.Create;
    try
      if ShowTree then
      begin
        WriteLn('Dependency tree:');
        WriteLn('');
        WriteLn(ChangeFileExt(ExtractFileName(BplPath), '') + '.bpl');
      end;

      GetAllDependencies(BplPath, AllDeps, 1, ShowTree);

      if not ShowTree then
      begin
        DepList := AllDeps.Keys.ToArray;
        TArray.Sort<string>(DepList);

        WriteLn('All dependencies (', Length(DepList), '):');
        WriteLn('');

        Found := 0;
        NotFound := 0;

        for DepName in DepList do
        begin
          DepPath := AllDeps[DepName];

          if Verbose then
          begin
            if DepPath <> '' then
            begin
              WriteLn('  ', DepName, '.bpl');
              WriteLn('    -> ', DepPath);
              Inc(Found);
            end
            else
            begin
              WriteLn('  ', DepName, '.bpl');
              WriteLn('    -> NOT FOUND');
              Inc(NotFound);
            end;
          end
          else
          begin
            WriteLn('  ', DepName, '.bpl');
            if DepPath <> '' then
              Inc(Found)
            else
              Inc(NotFound);
          end;
        end;

        if Verbose then
        begin
          WriteLn('');
          WriteLn('Summary:');
          WriteLn('  Total dependencies: ', Length(DepList));
          WriteLn('  Found: ', Found);
          WriteLn('  Not found: ', NotFound);
        end;
      end;
    finally
      AllDeps.Free;
    end;
  end
  else
  begin
    DirectDeps := TStringList.Create;
    try
      GetDirectDependencies(BplPath, DirectDeps);
      DirectDeps.Sort;

      WriteLn('Direct dependencies (', DirectDeps.Count, '):');
      WriteLn('');

      if Verbose then
      begin
        Found := 0;
        NotFound := 0;

        for DepName in DirectDeps do
        begin
          DepPath := GetBplPath(DepName + '.bpl');

          if not DepPath.IsEmpty then
          begin
            WriteLn('  ', DepName, '.bpl');
            WriteLn('    -> ', DepPath);
            Inc(Found);
          end
          else
          begin
            WriteLn('  ', DepName, '.bpl');
            WriteLn('    -> NOT FOUND');
            Inc(NotFound);
          end;
        end;

        WriteLn('');
        WriteLn('Summary:');
        WriteLn('  Total dependencies: ', DirectDeps.Count);
        WriteLn('  Found: ', Found);
        WriteLn('  Not found: ', NotFound);
      end
      else
      begin
        for DepName in DirectDeps do
          WriteLn('  ', DepName, '.bpl');
      end;
    finally
      DirectDeps.Free;
    end;
  end;
end;

var
  BplFile: string;
  Recursive: Boolean;
  ShowTree: Boolean;
  Verbose: Boolean;
  I: Integer;
begin
  try
    if ParamCount = 0 then
    begin
      ShowUsage;
      Exit;
    end;

    BplFile := '';
    Recursive := True;  // Default
    ShowTree := False;
    Verbose := False;

    for I := 1 to ParamCount do
    begin
      if ParamStr(I).StartsWith('-') then
      begin
        case ParamStr(I)[2] of
          'd', 'D': Recursive := False;
          'r', 'R': Recursive := True;
          't', 'T': ShowTree := True;
          'v', 'V': Verbose := True;
        else
          WriteLn('Unknown option: ', ParamStr(I));
          Exit;
        end;
      end
      else
        BplFile := ParamStr(I);
    end;

    if BplFile.IsEmpty then
    begin
      WriteLn('Error: No BPL file specified');
      WriteLn('');
      ShowUsage;
      Exit;
    end;

    ProcessBpl(BplFile, Recursive, ShowTree, Verbose);

  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
