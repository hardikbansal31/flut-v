[Setup]
AppId={{8B0122E0-85BE-4199-8C8E-C9C96317839C}
AppName=Penguin
AppVersion=1.0.0
AppPublisher=Penguin
DefaultDirName={autopf}\Penguin
DisableProgramGroupPage=yes
OutputBaseFilename=Penguin_Installer
Compression=lzma
SolidCompression=yes
WizardStyle=modern
OutputDir=Output

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "build\windows\x64\runner\Release\penguin.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Penguin"; Filename: "{app}\penguin.exe"
Name: "{autodesktop}\Penguin"; Filename: "{app}\penguin.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\penguin.exe"; Description: "{cm:LaunchProgram,Penguin}"; Flags: nowait postinstall skipifsilent
