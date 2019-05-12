program BitmapEditor;

uses
  Vcl.Forms,
  RotateBitmapUnit in '..\..\Shared\RotateBitmapUnit.pas',
  BitMapEditorDialog in 'BitMapEditorDialog.pas' {BMEditorMain},
  ProjectTestMain in 'ProjectTestMain.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
