#ifndef AppSourceDir
  #define AppSourceDir "..\dist\windows\Mazikty"
#endif

#ifndef OutputDir
  #define OutputDir "..\dist\windows\Installer"
#endif

#define MyAppName "مازيكتي - Mazikty"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Mazikty Music"
#define MyAppURL "https://github.com/Abdelrohmanaliabas"
#define MyAppExeName "mazikty.exe"
#define MyAppIcon "..\windows\runner\resources\app_icon.ico"

[Setup]
AppId={{5E789B12-42FA-4D78-903C-9A82D123EF01}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\Mazikty
DisableProgramGroupPage=yes
OutputDir={#OutputDir}
OutputBaseFilename=Mazikty-Setup-v{#MyAppVersion}
SetupIconFile={#MyAppIcon}
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#AppSourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
