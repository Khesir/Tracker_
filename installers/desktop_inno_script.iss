; Inno Setup script for trackr_

#define MyAppName "trackr_"
#define MyAppVersion "0.1.3"
#define MyAppPublisher "Khesir"
#define MyAppURL "https://keep-track.khesir.com/"
#define MyAppExeName "time_track.exe"

; SourcePath is the directory containing this .iss file (installers\).
; RepoRoot is the project root, one level up.
#define RepoRoot SourcePath + "..\"
#define ReleaseDir RepoRoot + "build\windows\x64\runner\Release"

[Setup]
AppId={{C3E7F214-9A51-4D72-B8F3-6A2D9E4C1B08}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
UninstallDisplayIcon={app}\{#MyAppExeName}
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
DisableProgramGroupPage=yes
OutputDir={#SourcePath}
OutputBaseFilename=trackr-v0.1.3
SetupIconFile={#RepoRoot}windows\runner\resources\app_icon.ico
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "{#ReleaseDir}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#ReleaseDir}\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#ReleaseDir}\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
