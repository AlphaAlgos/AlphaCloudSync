; ==============================================================================
; AlphaCloudSync Windows Setup Installer (Inno Setup 6.x)
; Direct-Download Setup EXE: dist\AlphaCloudSync-Setup-x64.exe
; Publisher: Alpha Algorithms Company (MIT License)
; ==============================================================================

#define MyAppName "AlphaCloudSync"
#ifndef MyAppVersion
  #define MyAppVersion "1.2.9"
#endif
#define MyAppPublisher "Alpha Algorithms Company"
#define MyAppURL "https://github.com/AlphaAlgos/AlphaCloudSync"
#define MyAppExeName "AlphaCloudSync.exe"
#ifndef MyAppBuildDir
  #define MyAppBuildDir "..\..\dist"
#endif

[Setup]
AppId={{8F3D4E9C-6A21-4B8E-9C10-7A5B3E2F4C01}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
AppUpdatesURL={#MyAppURL}/releases
DefaultDirName={localappdata}\{#MyAppName}\app
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
LicenseFile=..\..\LICENSE
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir={#MyAppBuildDir}
OutputBaseFilename=AlphaCloudSync-Setup-x64
SetupIconFile=..\..\assets\AlphaCloudSync-icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName} {#MyAppVersion}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
DisableProgramGroupPage=yes
ChangesEnvironment=yes
CloseApplications=yes
RestartApplications=no
VersionInfoVersion={#MyAppVersion}.0
VersionInfoCompany={#MyAppPublisher}
VersionInfoProductName={#MyAppName}
VersionInfoProductVersion={#MyAppVersion}
VersionInfoDescription=AlphaCloudSync Windows Cloud Storage Studio Installer

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "arabic";  MessagesFile: "compiler:Languages\Arabic.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "french";  MessagesFile: "compiler:Languages\French.isl"
Name: "german";  MessagesFile: "compiler:Languages\German.isl"

[CustomMessages]
english.TaskAddPath=Add AlphaCloudSync to user PATH (enables CLI automation)
arabic.TaskAddPath=إضافة AlphaCloudSync إلى PATH (لتشغيل أوامر CLI)
spanish.TaskAddPath=Agregar AlphaCloudSync al PATH de usuario (CLI)
french.TaskAddPath=Ajouter AlphaCloudSync au PATH utilisateur (CLI)
german.TaskAddPath=AlphaCloudSync zum Benutzer-PATH hinzufügen (CLI)

english.TaskAutoStart=Start AlphaCloudSync quietly in System Tray with Windows
arabic.TaskAutoStart=تشغيل AlphaCloudSync بهدوء في شريط النظام مع بداية ويندوز
spanish.TaskAutoStart=Iniciar AlphaCloudSync en silencio con Windows
french.TaskAutoStart=Démarrer AlphaCloudSync discrètement avec Windows
german.TaskAutoStart=AlphaCloudSync leise im Infobereich mit Windows starten

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: "addtopath";   Description: "{cm:TaskAddPath}";       GroupDescription: "{cm:AdditionalIcons}"
Name: "autostart";   Description: "{cm:TaskAutoStart}";     GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#MyAppBuildDir}\AlphaCloudSync.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\LICENSE";                 DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\README.md";               DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#MyAppName}\{#MyAppName}";           Filename: "{app}\{#MyAppExeName}"
Name: "{autoprograms}\{#MyAppName}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}";                         Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "{#MyAppName}"; ValueData: """{app}\{#MyAppExeName}"" --minimized"; Tasks: autostart; Flags: uninsdeletevalue

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
procedure EnvAddPath(PathToAdd: string);
var
  Paths: string;
begin
  if not RegQueryStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', Paths) then
    Paths := '';
  if Pos(';' + Uppercase(PathToAdd) + ';', ';' + Uppercase(Paths) + ';') > 0 then
    exit;
  if (Length(Paths) > 0) and (Paths[Length(Paths)] <> ';') then
    Paths := Paths + ';';
  Paths := Paths + PathToAdd;
  RegWriteExpandStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', Paths);
end;

procedure EnvRemovePath(PathToRemove: string);
var
  Paths: string;
  P: Integer;
begin
  if not RegQueryStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', Paths) then
    exit;
  P := Pos(';' + Uppercase(PathToRemove) + ';', ';' + Uppercase(Paths) + ';');
  if P = 0 then exit;
  Delete(Paths, P, Length(PathToRemove));
  StringChangeEx(Paths, ';;', ';', True);
  if (Length(Paths) > 0) and (Paths[1] = ';') then
    Delete(Paths, 1, 1);
  if (Length(Paths) > 0) and (Paths[Length(Paths)] = ';') then
    Delete(Paths, Length(Paths), 1);
  RegWriteExpandStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', Paths);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if (CurStep = ssPostInstall) and WizardIsTaskSelected('addtopath') then
    EnvAddPath(ExpandConstant('{app}'));
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
    EnvRemovePath(ExpandConstant('{app}'));
end;
