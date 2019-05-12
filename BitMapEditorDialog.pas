//License <---- Read me
//MIT License
//
//Copyright (c) 2019 Everest Software LLC https://www.hmisys.com
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.

unit BitMapEditorDialog;

interface

uses Winapi.Windows,Winapi.Messages,System.SysUtils,System.Variants,System.Classes,
     Vcl.Graphics,Vcl.Controls,Vcl.Forms,Vcl.Dialogs,Vcl.ExtCtrls,Vcl.Menus,
     System.ImageList,Vcl.ImgList,Vcl.StdCtrls,Vcl.ComCtrls,Vcl.ToolWin,Vcl.Grids;

type
 TBMEditorMain = class;
 TPointsArray = array of TPoint;
 TBMDrawingSurface = class;

{$REGION 'bmSettingsRecord define'}
 bmSettingsRec = record
  bitmap:TBitmap;
  colors:array[0..29] of TColor;
  canAlterSize:boolean;
  windowTop,windowLeft,windowWidth,windowHeight,maxUndoCount:integer;
  maxBitmapWidth,maxBitmapHeight,minBitmapWidth,minBitmapHeight:integer; //set to -1 to ignore
  procedure AssignIn(inSettings:bmSettingsRec);
  procedure AssignOut(inSettings:bmSettingsRec);
  procedure Initialize;
 end;
{$ENDREGION}

{$REGION 'seletRectsRec'}
 selectRectsRec = record
  index:integer;
  totalRect:TRect;
  edgeRects:array [0..7] of TRect;
  drawingSurface:TBMDrawingSurface;
  procedure DrawLineSelectionRectangles(aCanvas:TCanvas);
  procedure DrawSelectionRectangle(aCanvas:TCanvas);
  procedure DrawSelectionRectangles(aCanvas:TCanvas);
  procedure GetWidthHeight(var w,h:integer);
  function PointInResizeRectangle(aPt:TPoint):integer;
  function PointInTotalRectangle(aPt: TPoint):boolean;
 end;
{$ENDREGION}

{$REGION 'selectionRecord'}
 selectionRecord = record
  clipRgn:HRGN;
  bMap:TBitmap;
  pointsCount:integer;
  rects:selectRectsRec;
  active,moving,resizing:boolean;
  pointsArray:TPointsArray;
  procedure CopyToBitMapFromCanvas(aCanvas:TCanvas; aRect:TRect);
  procedure Draw(aCanvas:TCanvas);
  procedure Move(x,y:integer);
  function PointInBounds(aPt:TPoint):boolean;
  function PointInResize(aPt:TPoint):integer;
  procedure Reset;
  procedure ResetPointsVaribles;
 end;
{$ENDREGION}

{$REGION 'TBMDrawingSurface define'}
 TBMDrawingSurface = class(TCustomPanel)
 protected
  procedure Paint;override;
  procedure WmEraseBkgnd(var Msg: TWmEraseBkgnd);message WM_ERASEBKGND;
 private
  scaleIndex:integer;
  xForm,normalxForm:TXForm;                 //used for scaling
  selectRec:selectionRecord;
  property canvas;
  property OnMouseMove;
  property OnMouseUp;
  property OnMouseDown;
  procedure Draw;
  function GetScaleAmount:single;
  function GetScalePercent:string;
  procedure SetPenForpmNotXor(pStyle:TPenStyle = psDot);
  procedure SetScalingIfOn;
  procedure SetScalingNormal;
  procedure SetUp(w,h:integer);
  procedure TearDown;
 end;
{$ENDREGION}

{$REGION 'graphic element define'}
 geRecord = record
  bMap:TBitmap;
  shapeType:integer;         //same as tool button values
  penStyle:TPenStyle;
  brushStyle:TBrushStyle;
  selectRect:selectRectsRec;
  penColor,fillColor:TColor;
  drawSurface:TBMDrawingSurface;
  penWidth,pointsCount:integer;
  pointsArray:TPointsArray;
  selected,moving,resizing:boolean;
  text,fontName:string;
  fontSize:integer;
  fontStyle:TFontStyles;
  fontOpaque:boolean;
  procedure Assign(var varRec:geRecord);
  procedure Destroy;
  procedure Draw(aCanvas:TCanvas);
  procedure Move(x,y:integer);
  function PointInBounds(aPt:TPoint):boolean;
  function PointInResize(aPt:TPoint):integer;
  procedure ResizeComplete;
  procedure SelectionRectangleChange(diffPt:TPoint; boundRect:TRect);
  function TestMouseDownBitmapStyle(x,y:integer):boolean;
  procedure TransferPolyPointToCanvas(aCanvas:TCanvas);
 end;
{$ENDREGION}

{$REGION 'TUndoItem'}
 TUndoItem = class
  aPt:TPoint;                           //for moves
  bMap:TBitMap;
  clipRgn:HRGN;
  action:integer;                       //see consts below
  penStyle:TPenStyle;
  brushStyle:TBrushStyle;
  totalRect,redoRect:TRect;
  penColor,fillColor:TColor;
  shapeType,penWidth:integer;
  destructor Destroy;override;
  function SaveFromGE(ge:geRecord):boolean;
  procedure SaveFromUi(unUI:TUndoItem);
  procedure SaveToGE(var ge:geRecord);
 end;
{$ENDREGION}

{$REGION 'TUndoController'}
 TUndoController = class
  index:integer;
  undoList:TList;
  form:TBMEditorMain;
  procedure FreeUndoList;
  constructor Create;
  destructor Destroy;override;
  procedure PreSaveCheck;
  procedure RedoUserAction;
  procedure SaveAttAChangeAction(action:integer);
  procedure SaveBitmap(action:integer);
  procedure SaveCreateAction(action:integer);
  procedure SaveMoveAction(action:integer; aPt:TPoint);
  procedure SaveResizeAction(action:integer; aRect:TRect);
  procedure UndoUserAction;
  procedure ZeroListOfNonBMSave;
 end;
{$ENDREGION}

{$REGION 'resizeRecord'}
  resizeRecord = record
   mode:integer;        //0=percentage, 1 = pixels
   horzValue,vertValue:integer;
   keepAspectRatio:boolean;
   ratio:double;
   inRect:TRect;
   isGE:boolean;                //if false is select rec
   procedure Reset;
  end;
{$ENDREGION}

 TBMEditorMain = class(TForm)
    TopMenuBar: TMainMenu;
    FileMI: TMenuItem;
    EditMI: TMenuItem;
    SaveAndExitMI: TMenuItem;
    ExitMI: TMenuItem;
    N1: TMenuItem;
    PropertiesMI: TMenuItem;
    UndoMI: TMenuItem;
    RedoMI: TMenuItem;
    N2: TMenuItem;
    CutMI: TMenuItem;
    CopyMI: TMenuItem;
    PasteMI: TMenuItem;
    TopPanel: TPanel;
    N3: TMenuItem;
    SelectallMI: TMenuItem;
    N4: TMenuItem;
    RotateMI: TMenuItem;
    ResizeMI: TMenuItem;
    ToolsBtnBar: TToolBar;
    PencilBtn: TToolButton;
    ToolBarImageList: TImageList;
    BucketBtn: TToolButton;
    TextBtn: TToolButton;
    EraserBtn: TToolButton;
    DropperBtn: TToolButton;
    ToolBar1: TToolBar;
    NoFillBtn: TToolButton;
    BrushSolidBtn: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    FillImageList: TImageList;
    ToolButton8: TToolButton;
    SelectToolBar: TToolBar;
    SelectBtn: TToolButton;
    FreeSelectBtn: TToolButton;
    SelectImageList: TImageList;
    CircleBtn: TToolButton;
    RectangleBtn: TToolButton;
    LineToolBtn: TToolButton;
    RoundRectBtn: TToolButton;
    PenWidthCombo: TComboBox;
    PenStyleCombo: TComboBox;
    PenPaintBox: TPaintBox;
    FillPaintBox: TPaintBox;
    ColorGrid: TDrawGrid;
    OnlyColorDialog: TColorDialog;
    MainScrollBox: TScrollBox;
    PropertiesPanel: TPanel;
    PropertyCloseBtn: TButton;
    Label1: TLabel;
    Label2: TLabel;
    BMHeightEdit: TEdit;
    BMWidthEdit: TEdit;
    TextPanel: TPanel;
    Label4: TLabel;
    TextEditCloseBtn: TButton;
    FontCombo: TComboBox;
    FontNameLbl: TLabel;
    BoldCB: TCheckBox;
    ItalicCB: TCheckBox;
    UnderlineCB: TCheckBox;
    StrikeoutCB: TCheckBox;
    FontSizeComboLbl: TLabel;
    FontSizeCombo: TComboBox;
    OpaqueCB: TCheckBox;
    TextMemoEdit: TMemo;
    FlipMI: TMenuItem;
    FlipHorizontalMI: TMenuItem;
    FlipverticalMI: TMenuItem;
    ResizePanel: TPanel;
    ResizePanelCancelBtn: TButton;
    ResizePanelOKBtn: TButton;
    ResizeRG: TRadioGroup;
    ResizeHorizontalLbl: TLabel;
    ReaizeVerticalLbl: TLabel;
    ResizeHorzEdit: TEdit;
    ResizeVertEdit: TEdit;
    ResizeMaintainCB: TCheckBox;
    BottomPanel: TPanel;
    BottomBar: TStatusBar;
    ZoomPanel: TPanel;
    ZoomTrackBar: TTrackBar;
    ZoomLabel: TLabel;
    procedure ExitMIClick(Sender: TObject);
    procedure PencilBtnClick(Sender: TObject);
    procedure SelectBtnClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure PenWidthComboDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
    procedure PenStyleComboDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
    procedure PenPaintBoxClick(Sender: TObject);
    procedure PenPaintBoxPaint(Sender: TObject);
    procedure ColorGridDrawCell(Sender: TObject; ACol, ARow: Integer;Rect: TRect; State: TGridDrawState);
    procedure ColorGridMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ColorGridDblClick(Sender: TObject);
    procedure PropertiesMIClick(Sender: TObject);
    procedure PropertyCloseBtnClick(Sender: TObject);
    procedure PenWidthComboSelect(Sender: TObject);
    procedure PenStyleComboSelect(Sender: TObject);
    procedure NoFillBtnClick(Sender: TObject);
    procedure UndoMIClick(Sender: TObject);
    procedure EditMIClick(Sender: TObject);
    procedure TopPanelMouseEnter(Sender: TObject);
    procedure BoldCBClick(Sender: TObject);
    procedure FontComboClick(Sender: TObject);
    procedure TextMemoEditChange(Sender: TObject);
    procedure TextEditCloseBtnClick(Sender: TObject);
    procedure CopyMIClick(Sender: TObject);
    procedure CutMIClick(Sender: TObject);
    procedure PasteMIClick(Sender: TObject);
    procedure SelectallMIClick(Sender: TObject);
    procedure RotateMIClick(Sender: TObject);
    procedure ResizeMIClick(Sender: TObject);
    procedure FlipHorizontalMIClick(Sender: TObject);
    procedure ResizePanelCancelBtnClick(Sender: TObject);
    procedure ResizeHorzEditChange(Sender: TObject);
    procedure ResizePanelOKBtnClick(Sender: TObject);
    procedure ResizeRGClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure ZoomTrackBarChange(Sender: TObject);
    procedure FileMIClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure SaveAndExitMIClick(Sender: TObject);
  protected
    procedure AcceptFiles(var Message:TMessage ); message WM_DROPFILES;
  private
    ge:geRecord;
    workBM:TBitmap;
    brushStlye:TBrushStyle;
    undoer:TUndoController;
    resizeRec:resizeRecord;
    penColor,fillColor:TColor;
    leftMouseDownActive:boolean;
    drawSurface:TBMDrawingSurface;
    eraserPointsArray:TPointsArray;
    mouseDownPt,mouseAtNowPoint:TPoint;
    selectedColor,selectedTool,eraserPointsCount:integer;

    procedure BlockResizeChangeEvent(blockIt:boolean);
    procedure DoBucket(Button: TMouseButton);
    procedure DoEraser(aPt:TPoint);
    procedure DeSelectAllOnToolBar(aBar:TToolBar);
    procedure DoFreeSelectToolMouseUp;
    procedure DrawSurfaceMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure DrawSurfaceMouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
    procedure DrawSurfaceMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure DropperMouseDown(Button: TMouseButton);
    procedure EndGECreation;
    procedure EndGETextCreation;
    procedure FillRectangleWithFillColor(aRect:TRect);
    procedure HandleMouseDownInSelectionRectangle(index:integer);

    procedure NewGEMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure NewGEMouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
    procedure NewGEMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure NewGELineMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

    procedure NewGEPolyMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure NewGEPolyMouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
    procedure NewGEPolyMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

    procedure NewGETextMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure NewGETextMouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
    procedure NewGETextMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

    procedure RestoreOnMouseKeyEvents;
    procedure SaveTextStuffToGE;
    procedure SelectionMadeMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure SelectionMadeMouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
    procedure SelectionMadeMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure SetFillColor(aColor:TColor);
    procedure SetGeProperties;
    procedure SetSizesForDrawing;
    procedure SetToolButton(value:integer);
    procedure ShowHideRezisePanel(state:boolean);
    procedure ShowHideTextPanel(state:boolean);
    procedure UndoRedo(which:integer);
    procedure UpdateStatusBar(x:integer = 0; y:integer = 0);
    procedure ZoomTheViewFinal;
  public
    { Public declarations }
  end;

  function LaunchBitMapEditor(var inSettings:bmSettingsRec):boolean;

implementation

{$R *.dfm}
{$R BMCursor.res}

uses System.UITypes,System.Types,Math,Vcl.Clipbrd,RotateBitmapUnit,Winapi.ShellAPI,
     Winapi.ShlObj,Winapi.ActiveX,System.Win.ComObj,Vcl.Imaging.pngimage,Vcl.Imaging.jpeg;

var
 gSettings:bmSettingsRec;
 BMEditorMain:TBMEditorMain;

function LaunchBitMapEditor(var inSettings:bmSettingsRec):boolean;
begin
 gSettings.AssignIn(inSettings);
 BMEditorMain:=TBMEditorMain.Create(nil);
 try
  result:=(BMEditorMain.ShowModal = mrOk);
  inSettings.AssignOut(gSettings);
 finally
  BMEditorMain.Release;
 end;
end;

{$REGION 'const'}
const
 cComboColor            = $00FF8000;
 cOurFont               = 'Calibri';
 cWordClear             = 'Clear';
 cBuckCursor            = 1;
 cEraserCursor          = 2;

 cSelectTool            = 0;                    cFreeSelectTool         = 1;
 cPencilTool            = 2;                    cTextTool               = 3;
 cBucketTool            = 4;                    cLineTool               = 5;
 {cZoomTool              = 6;}                  cRectangleTool          = 7;
 cEraserTool            = 8;                    cCircleTool             = 9;
 cDropperTool           = 10;                   cRoundRectTool          = 11;
 cBitmapTool            = 255;

//bottom status bar
 cBBSpacer              = 0;                    cBBx                    = 2;
 cBBy                   = 4;                    cBBw                    = 6;
 cBBh                   = 8;                    cBBScale                = 9;

//undo
 cUndoGECreate          = 1;                    cUndoSelectCreate       = 2;
 cUndoSelectMove        = 3;                    cUndoGEResize           = 4;
 cUndoSelectResize      = 5;                    cUndoGEAttributeChange  = 6;
 cUndoGEMove            = 7;                    cUndoSaveBM             = 8;
 cUndoSelectFreeCreate  = 9;

 ROP_DstCopy            = $00AA0029;//$00220326;

type
 scaleRecord = record
  amount:single;
  percentString:string;
end;

var
 cScaleRecords: array [0..9] of scaleRecord =
  ((amount:0.25;         percentString:'25'),
   (amount:0.5;          percentString:'50'),
   (amount:0.75;         percentString:'75'),
   (amount:1.0;          percentString:'100'),
   (amount:1.25;         percentString:'125'),
   (amount:1.50;         percentString:'150'),
   (amount:1.75;         percentString:'175'),
   (amount:2.0;          percentString:'200'),
   (amount:4.0;          percentString:'400'),
   (amount:8.0;          percentString:'800'));

{$ENDREGION}

{$REGION 'misc functions'}
function CalculateOutsideRectangleForPolygon(pap:TPointsArray; count:integer):TRect;
var
 aPoint:TPoint;
 i,left,top,right,bottom:integer;
begin
//we need to determine the rectangle that bounds the points
 left:=maxInt;
 top:=maxInt;
 right:=0;
 bottom:=0;
 for i:= 0 to count - 1 do
  begin
   aPoint:=pap[i];
   if (aPoint.x < left) then
    left:=aPoint.x;
   if (aPoint.x > right) then
    right:=aPoint.x;
   if (aPoint.y < top) then
    top:=aPoint.y;
   if (aPoint.y > bottom) then
    bottom:=aPoint.y;
  end;
 result:=Rect(left,top,right,bottom);
end;

procedure DetermineSelectRects(ownerRect:TRect; var selectRects:array of TRect);
var
 midH,midV:integer;
begin
//top left
 selectRects[0].left:=ownerRect.left - 3;
 selectRects[0].top:=ownerRect.top - 3;
 selectRects[0].right:=ownerRect.left + 3;
 selectRects[0].bottom:=ownerRect.top + 3;
//top middle
 midH:=(ownerRect.right + ownerRect.left) div 2;
 selectRects[1].left:=midH - 3;
 selectRects[1].top:=ownerRect.top - 3;
 selectRects[1].right:=midH + 3;
 selectRects[1].bottom:=ownerRect.top + 3;
//top right
 selectRects[2].left:=ownerRect.right - 3;
 selectRects[2].top:=ownerRect.top - 3;
 selectRects[2].right:=ownerRect.right + 3;
 selectRects[2].bottom:=ownerRect.top + 3;
//right middle
 midV:=(ownerRect.bottom + ownerRect.top) div 2;
 selectRects[3].left:=ownerRect.right - 3;
 selectRects[3].top:=midV - 3;
 selectRects[3].right:=ownerRect.right + 3;
 selectRects[3].bottom:=midV + 3;
//right bottom
 selectRects[4].left:=ownerRect.right - 3;
 selectRects[4].top:=ownerRect.bottom - 3;
 selectRects[4].right:=ownerRect.right + 3;
 selectRects[4].bottom:=ownerRect.bottom + 3;
//bottom middle
 selectRects[5]:=selectRects[1];
 OffsetRect(selectRects[5],0,(ownerRect.bottom - ownerRect.top));
//bottom left
 selectRects[6]:=selectRects[0];
 OffsetRect(selectRects[6],0,(ownerRect.bottom - ownerRect.top));
//middle left
 selectRects[7]:=selectRects[3];
 OffsetRect(selectRects[7],-(ownerRect.right - ownerRect.left),0);
end;

procedure DetermineSelectRectsLine(ownerRect:TRect; var selectRects:array of TRect);
begin
//start point
 selectRects[0].left:=ownerRect.left - 3;
 selectRects[0].top:=ownerRect.top - 3;
 selectRects[0].right:=ownerRect.left + 3;
 selectRects[0].bottom:=ownerRect.top + 3;
//end point
 selectRects[4].left:=ownerRect.right - 3;
 selectRects[4].top:=ownerRect.bottom - 3;
 selectRects[4].right:=ownerRect.right + 3;
 selectRects[4].bottom:=ownerRect.bottom + 3;
end;

function DuplicateHRGN(inHRGN:HRGN):HRGN;
begin
 result:=CreateRectRgn(0,0,0,0);
 CombineRgn(result,inHRGN,0,RGN_COPY);
end;

procedure FrameRectEX(aCanvas:TCanvas; rectangleToFrame:TRect);
begin
 with rectangleToFrame do
  aCanvas.Polygon([Point(left,top),
                   Point(right,top),                  //top line
                   Point(right, bottom),              //right line
                   Point(left, bottom)]);             //bottom line
end;

function GetFontsListSansAmpersand:TStringList;
var
 i:integer;
begin
 result:=TStringList.Create;
 Screen.ResetFonts;
 for i:=0 to Screen.Fonts.Count - 1 do
  if (pos('@',Screen.Fonts[i]) = 0) then
   result.Add(Screen.Fonts[i]);
end;

function ICONToBitmap(const fileName:string):TBitmap;
var
 hIcon:THandle;
 info:TIconInfo;
begin
 result:=nil;
 hIcon:=0;
 try
  hIcon:=LoadImage(0,PChar(fileName),IMAGE_ICON,0, 0,LR_LOADFROMFILE);
  if (hIcon = 0) then
   Exit;
  result:=TBitMap.Create;
  if not Assigned(result) then
   Exit;
  result.handleType:=bmDIB;
  GetIconInfo(hIcon,info);
  result.Width:=(info.xHotspot * 2);
  result.Height:=(info.yHotspot * 2);
  DrawIconEx(result.Canvas.Handle, 0, 0, hIcon, 0, 0, 0, 0, DI_IMAGE);
 finally
  if (hIcon <> 0) then
   DestroyIcon(hIcon);
 end;
end;

function IndexFromStringArray(const valueString:string; stringArray:array of string):integer;
var
 i:integer;
begin
 result:=-1;
 for i:= low(stringArray) to high(stringArray) do
  if (valueString = stringArray[i]) then
   begin
    result:=i;
    Break;
   end
end;

function IsLinkFile(const fName:string):boolean;
begin
 result:=(UpperCase(ExtractFileExt(fName)) = '.LNK');
end;

function LightenColor(percent:byte; aColor:TColor):TColor;
var
 r,g,b:integer;
begin
{$R-}
 r:=GetRValue(aColor);
 g:=GetGValue(aColor);
 b:=GetBValue(aColor);
 r:=Round((R * percent) / 100) + Round(255 - percent / 100 * 255);
 g:=Round((G * percent) / 100) + Round(255 - percent / 100 * 255);
 b:=Round((B * percent) / 100) + Round(255 - percent / 100 * 255);
 result:=RGB(r,g,b);
{$R+}
end;

procedure Lock45(left,top:integer; var right,bottom:integer);
var
 offSet:integer;
begin
 offSet:=abs(right - left);
 if right > left then
  right:=left + offSet          //1-2, 10-11 o clock
 else
  right:=left - offSet;         //4-5, 7-8

 if top > bottom then
  bottom:=top - offSet          //1-2, 10-11 o clock
 else
  bottom:=top + offSet;         //4-5, 7-8
end;

procedure LineLocking(left,top:integer; var right,bottom:integer);
var
 ratio:double;
begin
 if (right = left) or (bottom = top) then
  Exit;

 ratio:=abs((right - left) / (bottom - top));
 if ratio > 1.75 then
  bottom:=top           //we are closer to the horziontal plane
 else if ratio < 0.25 then
  right:=left           //we are closer to the vertical plane
 else
  Lock45(left,top,right,bottom);
end;

procedure MapArrayOfPoints(thePoints:TPointsArray; pointCount:integer;
                           sourceRectangle,destinationRectangle:TRect);
var
 i,x:integer;
 percentFromLeft,percentFromTop:double;
 sourceWidth,destinationWidth,sourceHeight,destinationHeight:integer;
begin

 sourceWidth:=sourceRectangle.right - sourceRectangle.left;
 sourceHeight:=sourceRectangle.bottom - sourceRectangle.top;

 destinationWidth:=destinationRectangle.right - destinationRectangle.left;
 destinationHeight:=destinationRectangle.bottom - destinationRectangle.top;

 for i:= 0 to pointCount - 1 do
  begin
//calculate the distance from the left edge of the source rectangle and then
//calculate the new point from the new rectangle
   x:=thePoints[i].x - sourceRectangle.left;

   if (sourceWidth <> 0) then
    percentFromLeft:=(x / sourceWidth)
   else
    percentFromLeft:=1;

   thePoints[i].x:=Round((percentFromLeft * destinationWidth) + destinationRectangle.left);

//do the same for the vertical value
   x:=thePoints[i].y - sourceRectangle.top;

   if (sourceHeight <> 0) then
    percentFromTop:=(x / sourceHeight)
   else
    percentFromTop:=1;

   thePoints[i].y:=Round((percentFromTop * destinationHeight) + destinationRectangle.top);
  end;
end;

procedure ResiseRect(i: integer; diffPt: TPoint; var aRect:TRect);
begin
 case i of
  0:
   begin
    aRect.Top:=aRect.Top + diffPt.Y;
    aRect.Left:=aRect.Left + diffPt.X;
   end;
  1:            aRect.Top:=aRect.Top + diffPt.Y;
  2:
   begin
    aRect.Top:=aRect.Top + diffPt.Y;
    aRect.Right:=aRect.Right + diffPt.X;
   end;
  3:            aRect.right:=aRect.right + diffPt.x;
  4:
   begin
    aRect.Bottom:=aRect.Bottom + diffPt.Y;
    aRect.Right:=aRect.Right + diffPt.X;
   end;
  5:            aRect.Bottom:=aRect.Bottom + diffPt.y;
  6:
   begin
    aRect.Bottom:=aRect.Bottom+ diffPt.Y;
    aRect.Left:=aRect.Left + diffPt.X;
   end;
  7:            aRect.Left:=aRect.Left + diffPt.x;
 end;
end;

function ResolveShortCutLink( const path: String ): String;
var
 link: IShellLink;
 storage:IPersistFile;
 filedata:TWin32FindData;
 buf: Array[0..MAX_PATH] of Char;
 widepath:WideString;
begin
 OleCheck(CoCreateInstance(CLSID_ShellLink, nil,CLSCTX_INPROC_SERVER,
                           IShellLink, link ));
 OleCheck(link.QueryInterface( IPersistFile,storage ));
 widepath:=path;
 Result:='';
 if Succeeded(storage.Load(@widepath[1], STGM_READ )) then
  if Succeeded(link.Resolve(GetActiveWindow, SLR_NOUPDATE )) then
   if Succeeded(link.GetPath(buf,sizeof(buf),filedata, SLGP_UNCPRIORITY)) then
    Result:=buf;
 storage := nil;
 link:= nil;
end;

procedure ScalePointFromNative(var x,y:integer; amount:single);
begin
 if (amount = 1) then         //if 1, we are not zoomed
  Exit;
 x:=round(x * amount);
 y:=round(y * amount);
end;

procedure ScalePointToNative(var x,y:integer; amount:single);
begin
 if (amount = 1) then   //if 1, we are not zoomed
  Exit;
 x:=round(x * (1 / amount));
 y:=round(y * (1 / amount));
end;

procedure ScaleRectangleFromNative(var aRect:TRect; amount:single);
begin
//if 1 then we are not zoomed
 if (amount = 1) then
  Exit;

 with aRect do
  begin
   left:=round(left * amount);
   top:=round(top * amount);
   right:=round(right * amount);
   bottom:=round(bottom * amount);
  end;
end;

procedure ScaleRectangleToNative(var aRect:TRect; amount:single);
begin
//if 1 then we are not zoomed
 if (amount = 1) then
  Exit;

 with aRect do
  begin
   left:=round(left * (1 / amount));
   top:=round(top * (1 / amount));
   right:=round(right * (1 / amount));
   bottom:=round(bottom * (1 / amount));
  end;
end;

procedure SetPenForpmNotXor(aCanvas:TCanvas; pStyle:TPenStyle = psDot);
begin
 aCanvas.pen.width:=1;
 aCanvas.pen.style:=pStyle;
 if (pStyle = psDot) then
  aCanvas.pen.mode:=pmNotXor
 else
  aCanvas.pen.mode:=pmCopy;

 aCanvas.pen.color:=clBlack xor clBlack;
 aCanvas.brush.color:=clWhite;
end;

function SubtractPoints(const pointA, pointB:TPoint):TPoint;
begin
 result.x:=pointA.x - pointB.x;
 result.y:=pointA.y - pointB.y
end;

procedure SwapTwo(var a,b:integer);inline;
var
 t:integer;
begin
 t:=b;
 b:=a;
 a:=t;
end;

procedure ValidateLine(var aRect:TRect);
begin
//we want the line left to always be the starting point
 if (aRect.left > aRect.right) then
  begin
   SwapTwo(aRect.left,aRect.right);
   SwapTwo(aRect.top,aRect.bottom);
  end;
end;

procedure ValidateRectangle(var aRect:TRect);
begin
//we want a rectangle left and top to be less than the right and bottom
 if (aRect.top > aRect.bottom) then
  SwapTwo(aRect.top,aRect.bottom);
 if (aRect.left > aRect.right) then
  SwapTwo(aRect.left,aRect.right);
end;
{$ENDREGION}

{$REGION 'bmSettingsRecord implement'}
procedure bmSettingsRec.AssignIn(inSettings:bmSettingsRec);
var                     //for incoming
 i:integer;
begin
 bitmap:=inSettings.bitmap;
 windowTop:=inSettings.windowTop;
 windowLeft:=inSettings.windowLeft;
 windowWidth:=inSettings.windowWidth;
 windowHeight:=inSettings.windowHeight;
 for i:= 0 to high(colors) do
  colors[i]:=inSettings.colors[i];

 maxBitmapWidth:=inSettings.maxBitmapWidth;
 maxBitmapHeight:=inSettings.maxBitmapHeight;
 minBitmapWidth:=inSettings.minBitmapWidth;
 minBitmapHeight:=inSettings.minBitmapHeight;

 maxUndoCount:=inSettings.maxUndoCount;
 canAlterSize:=inSettings.canAlterSize;
end;

procedure bmSettingsRec.AssignOut(inSettings:bmSettingsRec);
begin
 windowTop:=inSettings.windowTop;
 windowLeft:=inSettings.windowLeft;
 windowWidth:=inSettings.windowWidth;
 windowHeight:=inSettings.windowHeight;
end;

procedure bmSettingsRec.Initialize;
var
 i:integer;
begin
 windowTop:=100;
 windowLeft:=100;
 windowWidth:=800;
 windowHeight:=620;

 colors[0]:=clWhite;            colors[1]:=clBlack;             colors[2]:=clRed;
 colors[3]:=clGreen;            colors[4]:=clBlue;              colors[5]:=clYellow;
 colors[6]:=clNavy;             colors[7]:=clPurple;            colors[8]:=clTeal;
 colors[9]:=clGray;             colors[10]:=clSilver;           colors[11]:=clLime;
 colors[12]:=clMaroon;          colors[13]:=clOlive;            colors[14]:=clFuchsia;
 colors[15]:=clAqua;            colors[16]:=clLtGray;           colors[17]:=clDkGray;
 colors[18]:=clMoneyGreen;      colors[19]:=TColor($0080FF); //orange;
 for i:=20 to high(colors) do   //for customr colors
  colors[i]:=clNone;
//load any colors here

 maxBitmapWidth:=-1;            maxBitmapHeight:=-1;
 minBitmapWidth:=-1;            minBitmapHeight:=-1;

 maxUndoCount:=100;
 canAlterSize:=true;
end;
{$ENDREGION}

procedure TBMEditorMain.AcceptFiles(var Message: TMessage);
const
 cnMaxFileNameLen = 255;
 cFileExt:array [0..2] of string =('.bmp','.ico','.png');
 cBMPExt = 0;
 cICOExt = 1;
 cPNGExt = 2;
var
 newBitMap:TBitMap;
 fileExt,s1:string;
 index,nCount:integer;
 newPNGFile:TPngImage;
 acFileName:array [0..cnMaxFileNameLen] of char;
begin
 if ge.selected and not IsRectEmpty(ge.selectRect.totalRect)then
  EndGECreation;

 try
  RestoreOnMouseKeyEvents;
  drawSurface.selectRec.Reset;
  nCount:=DragQueryFile(Message.WParam,$FFFFFFFF,acFileName,cnMaxFileNameLen); //how many files
  if (nCount > 1) then
   begin
    ShowMessage('Only one file per drag and drop operation.');
    Exit;
   end;

  DragQueryFile(Message.WParam, 0, acFileName, cnMaxFileNameLen);
  fileExt:=LowerCase(ExtractFileExt(acFileName));
  s1:=acFileName;
  if IsLinkFile(s1) then
   s1:=ResolveShortCutLink(s1);
  if not FileExists(s1) then //make sure the file is there
   Exit;

  index:=IndexFromStringArray(fileExt,cFileExt);
  case index of
   cBMPExt:            //bmp
    begin
     newBitMap:=TBitMap.Create;
     if not Assigned(newBitMap) then
      Exit;

     newBitMap.handleType:=bmDIB;
     newBitMap.LoadFromFile(s1);
     if newBitMap.Empty then
      begin
       newBitMap.Free;
       Exit;
      end;
    end;
   cICOExt:           //ico
    begin
     newBitMap:=ICONToBitmap(s1);
     if not Assigned(newBitMap) or newBitMap.Empty then
      begin
       newBitMap.Free;
       Exit;
      end;
    end;
   cPNGExt:
    begin
     newBitMap:=TBitMap.Create;
     if not Assigned(newBitMap) then
      Exit;

     newPNGFile:=TPngImage.Create;
     if not Assigned(newPNGFile) then
      Exit;

     try
      newPNGFile.LoadFromFile(s1);
      newBitMap.SetSize(newPNGFile.Width,newPNGFile.Height);
      newBitMap.Canvas.CopyRect(Rect(0,0,newPNGFile.Width,newPNGFile.Height),
                                newPNGFile.Canvas,Rect(0,0,newPNGFile.Width,newPNGFile.Height));
     finally
      newPNGFile.Free;
     end;
    end
   else
    begin
     ShowMessage('Unknown file type' + ' ' + acFileName);
     Exit;
    end;
  end;

  if Assigned(ge.bMap) then
   ge.bMap.Free;

  ge.bMap:=newBitMap;
  ge.shapeType:=cBitmapTool;
  ge.selectRect.totalRect:=Rect(0,0,newBitMap.Width,newBitMap.Height);
  ge.selected:=true;
  undoer.SaveCreateAction(cUndoGECreate);
  drawSurface.OnMouseDown:=SelectionMadeMouseDown;
  drawSurface.OnMouseMove:=SelectionMadeMouseMove;
  drawSurface.OnMouseUp:=SelectionMadeMouseUp;
 finally
  DragFinish(Message.WParam);      // let Windows know that you're done
  drawSurface.Invalidate;
 end;
end;

procedure TBMEditorMain.BoldCBClick(Sender: TObject);
begin
 SaveTextStuffToGE;
end;

{$REGION 'color grid'}
procedure TBMEditorMain.BlockResizeChangeEvent(blockIt: boolean);
begin
 if blockIt then
  begin
   ResizeHorzEdit.OnChange:=nil;
   ResizeVertEdit.OnChange:=nil;
  end
 else
  begin
   ResizeHorzEdit.OnChange:=ResizeHorzEditChange;
   ResizeVertEdit.OnChange:=ResizeHorzEditChange;
  end;
end;

procedure TBMEditorMain.ColorGridDblClick(Sender: TObject);
var
 s1:string;
 dg:TDrawGrid;
 aColor:TColor;
 strList:TStringList;
 index,ACol,ARow,i:integer;
begin
 if not (Sender is TDrawGrid) then
  Exit;
 dg:=TDrawGrid(sender);
 ARow:=dg.row;
 ACol:=dg.col;

 index:=(ACol + (ARow * 10));
 if (index < 0) or (index > high(gSettings.colors)) then
  Exit;

 strList:=TStringList.Create;
 try
  for i:=20 to 29 do
   strList.Add('Color' + char(i + 45) + '=' + IntToHex(gSettings.colors[i],8));
  OnlyColorDialog.CustomColors.Assign(strList);
  OnlyColorDialog.Color:=gSettings.colors[index];
  if OnlyColorDialog.Execute then
   gSettings.colors[index]:=OnlyColorDialog.Color;

//save any changes to the custom colors
  strList.Assign(OnlyColorDialog.CustomColors);
  for i:=0 to 9 do
   begin
    s1:=strList[i];               //format is Color<letter>=<hex value>
    Delete(s1,1,7);
    aColor:=StringToColor('$' + s1);
    if (aColor <> clBlack) then
     gSettings.colors[i + 20]:=aColor;
   end;
  ColorGrid.Invalidate;
 finally
  strList.Free;
 end;
end;

procedure TBMEditorMain.ColorGridDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
var
 index:integer;
 dg:TDrawGrid;
begin
 if not (Sender is TDrawGrid) then
  Exit;

 dg:=TDrawGrid(sender);
 index:=(ACol + (ARow * 10));
 if gSettings.colors[index] = clNone then
  dg.Canvas.brush.color:=dg.Color
 else
  dg.Canvas.brush.color:=gSettings.colors[index];

 dg.Canvas.pen.style:=psClear;
 dg.Canvas.brush.Style:=bsSolid;
 dg.Canvas.Rectangle(rect);
 dg.Canvas.pen.style:=psSolid;
end;

procedure TBMEditorMain.ColorGridMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
 dg:TDrawGrid;
 index,ACol,ARow:integer;
begin
 if not (Sender is TDrawGrid) then
  Exit;

 dg:=TDrawGrid(sender);
 dg.MouseToCell(x,y,ACol,ARow);

 index:=(ACol + (ARow * 10));
 if (index < 0) or (index > high(gSettings.colors)) then
  Exit;
 if (gSettings.colors[index] = clNone) then
  Exit;

 if (selectedColor = 0) and (Button = mbLeft) then //right button is always bg color
  penColor:=gSettings.colors[index]
 else
  SetFillColor(gSettings.colors[index]);

 if ge.selected and not IsRectEmpty(ge.selectRect.totalRect) then
  begin
   undoer.SaveAttAChangeAction(cUndoGEAttributeChange);
   ge.penColor:=penColor;
   ge.fillColor:=fillColor;
   ge.drawSurface.Invalidate;
  end;

 PenPaintBox.Invalidate;
 FillPaintBox.Invalidate;
end;
{$ENDREGION}

procedure TBMEditorMain.CopyMIClick(Sender: TObject);
var
 aRect:TRect;
 tmp:TBitMap;
 newHRGN:HRGN;
 aMapFormat:word;
 aPalette:HPALETTE;
 aHandlePtr:pointer;
 aHandle,aData:THandle;
 memoryStream:TMemoryStream;
begin
 aHandle:=0;
 newHRGN:=0;
 tmp:=TBitMap.Create;
 memoryStream:=TMemoryStream.Create;
 try
  if not Assigned(tmp) then
   Exit;
  if not Assigned(memoryStream) then
   Exit;
  try
   tmp.HandleType:=bmDDB;
   tmp.PixelFormat:=pf32Bit;
   tmp.SetSize(drawSurface.selectRec.bMap.Width,drawSurface.selectRec.bMap.Height);
   aRect:=Rect(0,0,drawSurface.selectRec.bMap.Width,drawSurface.selectRec.bMap.Height);
   tmp.Canvas.Brush.Color:=fillColor;
   tmp.Canvas.Brush.Style:=bsSolid;
   tmp.Canvas.FillRect(aRect);

   if (drawSurface.selectRec.clipRgn <> 0) then
    begin
     newHRGN:=DuplicateHRGN(drawSurface.selectRec.clipRgn);
     OffsetRgn(newHRGN,-drawSurface.selectRec.rects.totalRect.Left,-drawSurface.selectRec.rects.totalRect.Top);
     SelectClipRgn(tmp.Canvas.Handle,newHRGN);
    end;

   tmp.Canvas.Draw(0,0,drawSurface.selectRec.bMap);
//   tmp.SaveToFile('c:\logs\tmp.bmp');
   Clipboard.Open;
   tmp.SaveToClipBoardFormat(aMapFormat,aData,aPalette);

//get some global memory and lock it down
   aHandle:=GlobalAlloc(GMEM_MOVEABLE and GMEM_DDESHARE,memoryStream.size);
   aHandlePtr:=GlobalLock(aHandle);
   Move(memoryStream.memory^,aHandlePtr^,memoryStream.size);    //copy the steam to the global memory
   ClipBoard.SetAsHandle(aMapFormat,aData);                     //tell the clipboard the data format
   GlobalUnlock(aHandle);
  except
   GlobalUnlock(aHandle);        //if it hoses up do not leave this memory hanging
   GlobalFree(aHandle);
  end;
 finally
  DeleteObject(newHRGN);
  Clipboard.Close;
  tmp.Free;
  memoryStream.Free;
 end;
end;

procedure TBMEditorMain.CutMIClick(Sender: TObject);
begin
 drawSurface.selectRec.Reset;
 drawSurface.Invalidate;
end;

procedure TBMEditorMain.DoBucket(Button: TMouseButton);
var
 aColor:TColor;
begin
 undoer.SaveBitmap(cUndoSaveBM);
 aColor:=workBM.canvas.pixels[mouseDownPt.x,mouseDownPt.Y];
 if (Button = mbLeft) then
  workBM.canvas.Brush.Color:=penColor
 else
  workBM.canvas.Brush.Color:=fillColor;
 workBM.canvas.FloodFill(mouseDownPt.x,mouseDownPt.Y,aColor,fsSurface);
 drawSurface.Invalidate;
end;

procedure TBMEditorMain.DoEraser(aPt:TPoint);
begin
 eraserPointsArray[eraserPointsCount]:=aPt;
 Inc(eraserPointsCount);
 workBM.Canvas.Pen.Style:=psSolid;
 workBM.Canvas.Pen.Width:=8;
 workBM.Canvas.Pen.Color:=fillColor;
 workBM.Canvas.Polyline(Copy(eraserPointsArray,0,eraserPointsCount));
 drawSurface.Invalidate;

 if (eraserPointsCount > 1000)  then
  begin                            //if gets too big a lag appears
   SetLength(eraserPointsArray,0);
   eraserPointsCount:=0;
   SetLength(eraserPointsArray,1001);
   eraserPointsArray[eraserPointsCount]:=aPt;
   Inc(eraserPointsCount);
  end;
end;

procedure TBMEditorMain.DeSelectAllOnToolBar(aBar:TToolBar);
var
 i:integer;
begin
 if not Assigned(aBar) then
  Exit;
 for i:=0 to aBar.ButtonCount - 1 do
  aBar.Buttons[i].Down:=false;
end;

procedure TBMEditorMain.DoFreeSelectToolMouseUp;
var
 w,h:integer;
 sizeRect:TRect;
 srcMap:TBitMap;
begin
 if (drawSurface.selectRec.pointsCount < 2) then
  Exit;

 drawSurface.selectRec.rects.totalRect:=CalculateOutsideRectangleForPolygon(drawSurface.selectRec.pointsArray,
                                                                            drawSurface.selectRec.pointsCount);
 drawSurface.selectRec.rects.GetWidthHeight(w,h);
 sizeRect:=Rect(0,0,w,h);

//create the region for clipping
 drawSurface.selectRec.clipRgn:=CreatePolygonRgn(drawSurface.selectRec.pointsArray[0],drawSurface.selectRec.pointsCount,WINDING);
 if (drawSurface.selectRec.clipRgn = 0) then
  Exit;

 srcMap:=TBitMap.Create;                //make it cleaner
 if not Assigned(srcMap) then
  Exit;
 srcMap.SetSize(w,h);
 try
  srcMap.Canvas.CopyRect(sizeRect,BMEditorMain.workBM.Canvas,drawSurface.selectRec.rects.totalRect);
//  srcMap.SaveToFile('c:\logs\srcMap.bmp');

  workBM.Canvas.Brush.Style:=brushStlye;
  workBM.Canvas.Brush.Color:=fillColor;
  FillRgn(workBM.Canvas.Handle,                 //destination
          drawSurface.selectRec.clipRgn,        //region
          workBM.Canvas.Brush.Handle);          //brush

  if Assigned(drawSurface.selectRec.bMap) then
   drawSurface.selectRec.bMap.Free;
  drawSurface.selectRec.bMap:=srcMap;

 finally
  drawSurface.selectRec.ResetPointsVaribles;
 end;

 drawSurface.selectRec.active:=true;
 drawSurface.OnMouseDown:=SelectionMadeMouseDown;
 drawSurface.OnMouseMove:=SelectionMadeMouseMove;
 drawSurface.OnMouseUp:=SelectionMadeMouseUp;
 undoer.SaveCreateAction(cUndoSelectFreeCreate);
 Screen.Cursor:=crSizeAll;
 drawSurface.Invalidate;
end;

procedure TBMEditorMain.DrawSurfaceMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
 if ssDouble in Shift then
  Exit;

 leftMouseDownActive:=true;
 mouseDownPt:=Point(x,y);
 ScalePointToNative(mouseDownPt.x,mouseDownPt.y,drawSurface.GetScaleAmount);
 UpdateStatusBar(mouseDownPt.x,mouseDownPt.y);

 if ge.selected and not IsRectEmpty(ge.selectRect.totalRect)then
  EndGECreation;

 drawSurface.selectRec.rects.totalRect:=Rect(mouseDownPt.x,mouseDownPt.y,mouseDownPt.x,mouseDownPt.y);
 case selectedTool of
  cSelectTool:;
  cFreeSelectTool:
   begin
    SetLength(drawSurface.selectRec.pointsArray,65535);
    drawSurface.selectRec.pointsCount:=0;

    drawSurface.SetPenForpmNotXor(psSolid);
    drawSurface.selectRec.pointsArray[drawSurface.selectRec.pointsCount]:=mouseDownPt;
    Inc(drawSurface.selectRec.pointsCount);
   end;
  cRectangleTool,cCircleTool,cRoundRectTool:
   begin
    ge.shapeType:=selectedTool;
    drawSurface.SetPenForpmNotXor(psSolid);
    NewGEMouseDown(Sender,Button,Shift,mouseDownPt.x,mouseDownPt.y);
    NewGEMouseMove(Sender,Shift,x,y);           //draw once for xor
    drawSurface.OnMouseDown:=NewGEMouseDown;
    drawSurface.OnMouseMove:=NewGEMouseMove;
    drawSurface.OnMouseUp:=NewGEMouseUp;
   end;
  cLineTool:
   begin
    ge.shapeType:=selectedTool;
    drawSurface.SetPenForpmNotXor(psSolid);
    NewGEMouseDown(Sender,Button,Shift,mouseDownPt.x,mouseDownPt.y);
    NewGEMouseMove(Sender,Shift,X,Y);           //draw once for xor
    drawSurface.OnMouseDown:=NewGEMouseDown;
    drawSurface.OnMouseMove:=NewGEMouseMove;
    drawSurface.OnMouseUp:=NewGELineMouseUp;
   end;
  cDropperTool:         DropperMouseDown(Button);
  cPencilTool:
   begin
    ge.shapeType:=selectedTool;
    NewGEPolyMouseDown(Sender,Button,Shift,mouseDownPt.x,mouseDownPt.y);
    drawSurface.OnMouseDown:=NewGEPolyMouseDown;
    drawSurface.OnMouseMove:=NewGEPolyMouseMove;
    drawSurface.OnMouseUp:=NewGEPolyMouseUp;
   end;
  cBucketTool:          DoBucket(Button);
  cEraserTool:
   begin
    undoer.SaveBitmap(cUndoSaveBM);
    eraserPointsCount:=0;
    SetLength(eraserPointsArray,65535);
   end;
  cTextTool:
   begin
    ge.shapeType:=selectedTool;
    ge.text:='';
    drawSurface.SetPenForpmNotXor(psSolid);
    NewGETextMouseDown(Sender,Button,Shift,mouseDownPt.x,mouseDownPt.y);
    NewGETextMouseMove(Sender,Shift,X,Y);           //draw once for xor
    drawSurface.OnMouseDown:=NewGETextMouseDown;
    drawSurface.OnMouseMove:=NewGETextMouseMove;
    drawSurface.OnMouseUp:=NewGETextMouseUp;
   end;
 end;
end;

procedure TBMEditorMain.DrawSurfaceMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
 aPoint:TPoint;
begin
 drawSurface.SetScalingIfOn;                        //is the user zooming

 aPoint:=Point(x,y);
 ScalePointToNative(aPoint.x,aPoint.y,drawSurface.GetScaleAmount);
 case selectedTool of
  cBucketTool:          Screen.Cursor:=cBuckCursor;
  cEraserTool:          Screen.Cursor:=cEraserCursor;
  else                  Screen.Cursor:=crDefault;
 end;

 if not leftMouseDownActive then
  begin
   UpdateStatusBar(x,y);
   Exit;
  end;

 case selectedTool of
  cSelectTool:
   begin
    drawSurface.selectRec.rects.DrawSelectionRectangle(drawSurface.canvas);     //clear out the old one
    drawSurface.selectRec.rects.totalRect.right:=aPoint.x;
    drawSurface.selectRec.rects.totalRect.bottom:=aPoint.y;
    drawSurface.selectRec.rects.DrawSelectionRectangle(drawSurface.canvas);     //clear out the old one
   end;
  cFreeSelectTool:
   begin
    mouseAtNowPoint:=Point(x,y);
    ScalePointToNative(mouseAtNowPoint.x,mouseAtNowPoint.y,drawSurface.GetScaleAmount);
    drawSurface.selectRec.pointsArray[drawSurface.selectRec.pointsCount]:=mouseAtNowPoint;
    Inc(drawSurface.selectRec.pointsCount);
    drawSurface.selectRec.Draw(drawSurface.canvas);
    UpdateStatusBar(x,y);
   end;
  cEraserTool:          DoEraser(Point(x,y));
 end;
 UpdateStatusBar(x,y);
 drawSurface.SetScalingNormal;
end;

procedure TBMEditorMain.DrawSurfaceMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

begin
 leftMouseDownActive:=false;
 case selectedTool of
  cDropperTool:         Exit;
  cEraserTool:
   begin
    SetLength(drawSurface.selectRec.pointsArray,0);
    Exit;
   end;
  cFreeSelectTool:
   begin
    DoFreeSelectToolMouseUp;
    Exit;
   end;
 end;

 ValidateRectangle(drawSurface.selectRec.rects.totalRect);

 if IsRectEmpty(drawSurface.selectRec.rects.totalRect) then
  Exit;

 case selectedTool of
  cSelectTool:
   begin
    drawSurface.selectRec.active:=true;
    //copy the area inside the selection rectangle
    drawSurface.selectRec.CopyToBitMapFromCanvas(workBM.Canvas,drawSurface.selectRec.rects.totalRect);
    //if the user moves the selection the background will be pre filled. no move not visible.
    FillRectangleWithFillColor(drawSurface.selectRec.rects.totalRect);
    drawSurface.selectRec.rects.DrawSelectionRectangle(drawSurface.canvas);
    drawSurface.OnMouseDown:=SelectionMadeMouseDown;
    drawSurface.OnMouseMove:=SelectionMadeMouseMove;
    drawSurface.OnMouseUp:=SelectionMadeMouseUp;
    undoer.SaveCreateAction(cUndoSelectCreate);
    Screen.Cursor:=crSizeAll;
    drawSurface.Invalidate;
   end;
 end;
end;

procedure TBMEditorMain.DropperMouseDown(Button: TMouseButton);
var
 aColor:TColor;
begin
 drawSurface.Paint;
 aColor:=workBM.canvas.pixels[mouseDownPt.x,mouseDownPt.Y];
 if (Button = mbLeft) then
  penColor:=aColor
 else
  SetFillColor(aColor);
 PenPaintBox.Invalidate;
 FillPaintBox.Invalidate;
end;

procedure TBMEditorMain.EditMIClick(Sender: TObject);
begin
 UndoMI.Enabled:=(undoer.undoList.Count > 0) and (undoer.index > 0);
 RedoMI.Enabled:=(undoer.index < undoer.undoList.Count);
 CopyMI.Enabled:=not IsRectEmpty(drawSurface.selectRec.rects.totalRect);
 CutMI.Enabled:=CopyMI.Enabled;
 RotateMI.Enabled:=CopyMI.Enabled;

 FlipMI.Enabled:=(not IsRectEmpty(drawSurface.selectRec.rects.totalRect)) or
                  (ge.selected and (ge.shapeType = cBitmapTool) and Assigned(ge.bMap));
 FlipHorizontalMI.Enabled:=FlipMI.Enabled;
 FlipverticalMI.Enabled:=FlipMI.Enabled;
 ResizeMI.Enabled:=(not IsRectEmpty(drawSurface.selectRec.rects.totalRect)) or ge.selected;
end;

procedure TBMEditorMain.EndGECreation;
label
 cancelSave;
begin
 undoer.SaveBitmap(cUndoSaveBM);
 ge.selected:=false;
 case ge.shapeType of
  cPencilTool:
   begin
    undoer.SaveBitmap(cUndoSaveBM);
    ge.TransferPolyPointToCanvas(workBM.Canvas);
    goto cancelSave;
   end;
  cTextTool:
   begin
    EndGETextCreation;
    goto cancelSave;
   end;
  cBitmapTool:
   if Assigned(ge.bMap) then
    begin
     undoer.SaveBitmap(cUndoSaveBM);
     ge.Draw(workBM.Canvas);
     FreeAndNil(ge.bMap);
     goto cancelSave;
    end
  else
   begin
    undoer.SaveBitmap(cUndoSaveBM);
    ValidateRectangle(ge.selectRect.totalRect);
   end;
 end;

 ge.Draw(workBM.Canvas);        //save it to the canvas

cancelSave:
 ge.selectRect.totalRect:=Rect(0,0,0,0);
end;

procedure TBMEditorMain.EndGETextCreation;
begin
 ge.selected:=false;
 if (ge.text <> '') then
  begin
   undoer.SaveBitmap(cUndoSaveBM);
   ge.Draw(workBM.Canvas);        //save it to the canvas
   drawSurface.Invalidate;
   ge.text:='';
   RestoreOnMouseKeyEvents;
  end;
 ShowHideTextPanel(false);
end;

procedure TBMEditorMain.FileMIClick(Sender: TObject);
begin
 PropertiesMI.Enabled:=gSettings.canAlterSize;
end;

procedure TBMEditorMain.FillRectangleWithFillColor(aRect:TRect);
begin
 workBM.Canvas.Brush.Style:=bsSolid;
 workBM.Canvas.Brush.Color:=fillColor;
 workBM.Canvas.FillRect(aRect);
end;

procedure TBMEditorMain.FlipHorizontalMIClick(Sender: TObject);
var
 bitMap:TBitMap;
 direction,w,h:integer;
begin
 if not (sender is TMenuItem) then
  Exit;

 if not Assigned(drawSurface.selectRec.bMap) then
  Exit;

 if (not IsRectEmpty(drawSurface.selectRec.rects.totalRect)) then
  bitMap:=drawSurface.selectRec.bMap
 else if (ge.selected and (ge.shapeType = cBitmapTool) and Assigned(ge.bMap)) then
  bitMap:=ge.bMap
 else
  Exit;

 direction:=TMenuItem(Sender).tag;
 SetStretchBltMode(bitMap.canvas.handle,COLORONCOLOR);
 w:=bitMap.width;
 h:=bitMap.height;
 bitMap.canvas.CopyMode:=cmSrcCopy;

 SetStretchBltMode(bitMap.canvas.handle,COLORONCOLOR);

 case direction of
  0:                                                           //horz
   StretchBlt(bitMap.canvas.handle,w,0,-(w + 1),h,bitMap.canvas.handle,0,0,w + 1,h,SRCCOPY);
  1:                                                           //vert
   StretchBlt(bitMap.canvas.handle,0,h,w,-(h + 1),bitMap.canvas.handle,0,0,w,h + 1,SRCCOPY);
 end;
 drawSurface.Invalidate;
end;

procedure TBMEditorMain.HandleMouseDownInSelectionRectangle(index:integer);
begin
 if ge.selected then
  begin
   ge.moving:=(index = - 1);
   ge.resizing:=(index <> - 1);
   ge.selectRect.index:=index;
//when the user is resizing a line and wants to lock the line the starting point must be the line point
//not the mouse down point
  if (ge.selectRect.index <> -1) then
   mouseAtNowPoint:=CenterPoint(ge.selectRect.edgeRects[ge.selectRect.index]);
  end
 else if drawSurface.selectRec.active then
  begin
   drawSurface.selectRec.moving:=(index = - 1);
   drawSurface.selectRec.resizing:=(index <> - 1);
   drawSurface.selectRec.rects.index:=index;
  end;
end;

procedure TBMEditorMain.NewGEMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
 ge.selectRect.totalRect:=Rect(x,y,x,y);
 SetGeProperties;
end;

procedure TBMEditorMain.NewGEMouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
var
 mouseAtNowPointNew:TPoint;
 selectRectIndex:integer;
begin
 if not leftMouseDownActive then
  Exit;

 drawSurface.Paint;
// ge.Draw(drawSurface.canvas);
 mouseAtNowPointNew:=Point(x,y);
 ScalePointToNative(mouseAtNowPointNew.x,mouseAtNowPointNew.y,drawSurface.GetScaleAmount);

 if (ssShift in Shift) then          //is the user trying to lock the line
  begin
   selectRectIndex:=ge.PointInResize(mouseAtNowPointNew);
   if (ge.shapeType in [cLineTool]) and (selectRectIndex <> 0) then
    LineLocking(ge.selectRect.totalRect.left,ge.selectRect.totalRect.top,x,y);
  end;

 ge.selectRect.totalRect.right:=mouseAtNowPointNew.x;
 ge.selectRect.totalRect.bottom:=mouseAtNowPointNew.y;
 ge.Draw(drawSurface.canvas);
 drawSurface.canvas.pen.mode:=pmCopy;                   //restore this setting

 UpdateStatusBar(x,y);
end;

procedure TBMEditorMain.NewGEMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
 leftMouseDownActive:=false;
 drawSurface.Invalidate;
 ValidateRectangle(ge.selectRect.totalRect);

 if IsRectEmpty(ge.selectRect.totalRect) then
  begin
   drawSurface.OnMouseDown:=DrawSurfaceMouseDown;
   drawSurface.OnMouseMove:=DrawSurfaceMouseMove;
   drawSurface.OnMouseUp:=DrawSurfaceMouseUp;
   Exit;
  end;

 drawSurface.OnMouseDown:=SelectionMadeMouseDown;
 drawSurface.OnMouseMove:=SelectionMadeMouseMove;
 drawSurface.OnMouseUp:=SelectionMadeMouseUp;

 ge.selected:=true;
 undoer.SaveCreateAction(cUndoGECreate);
 UpdateStatusBar(x,y);
end;

procedure TBMEditorMain.NewGELineMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
 leftMouseDownActive:=false;
 drawSurface.Invalidate;

 if (ge.selectRect.totalRect.Right = ge.selectRect.totalRect.left) and
    (ge.selectRect.totalRect.bottom = ge.selectRect.totalRect.Top) then
  begin
   drawSurface.OnMouseDown:=DrawSurfaceMouseDown;
   drawSurface.OnMouseMove:=DrawSurfaceMouseMove;
   drawSurface.OnMouseUp:=DrawSurfaceMouseUp;
   Exit;
  end;

 ValidateLine(ge.selectRect.totalRect);
 drawSurface.OnMouseDown:=SelectionMadeMouseDown;
 drawSurface.OnMouseMove:=SelectionMadeMouseMove;
 drawSurface.OnMouseUp:=SelectionMadeMouseUp;

 ge.selected:=true;
 undoer.SaveCreateAction(cUndoGECreate);
 UpdateStatusBar(x,y);
end;

procedure TBMEditorMain.NewGEPolyMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
// ScalePointToNative(mouseDownPt.x,mouseDownPt.y,drawSurface.GetScaleAmount);
 ge.selectRect.totalRect:=Rect(mouseDownPt.X,mouseDownPt.Y,mouseDownPt.X,mouseDownPt.Y);
 SetGeProperties;
 SetLength(ge.pointsArray,65535);
 ge.pointsArray[ge.pointsCount]:=mouseDownPt;
 Inc(ge.pointsCount);
end;

procedure TBMEditorMain.NewGEPolyMouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
begin
 mouseAtNowPoint:=Point(x,y);
 ge.pointsArray[ge.pointsCount]:=mouseAtNowPoint;
 Inc(ge.pointsCount);
 ge.Draw(drawSurface.canvas);
 UpdateStatusBar(x,y);
end;

procedure TBMEditorMain.NewGEPolyMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
 i:integer;
 tempMemory:TPointsArray;
begin
 leftMouseDownActive:=false;
 drawSurface.Invalidate;

 SetLength(tempMemory,ge.pointsCount);

 for i:= 0 to ge.pointsCount - 1 do                   //now copy over the points
  tempMemory[i]:=ge.pointsArray[i];
 SetLength(ge.pointsArray,0);
 ge.pointsArray:=tempMemory;

//determine the rectangle that bounds the points
 ge.selectRect.totalRect:=CalculateOutsideRectangleForPolygon(ge.pointsArray,ge.pointsCount);

 if IsRectEmpty(ge.selectRect.totalRect) then
  begin
   SetLength(ge.pointsArray,0);
   ge.pointsCount:=0;
   RestoreOnMouseKeyEvents;
   Exit;
  end;

 drawSurface.OnMouseDown:=SelectionMadeMouseDown;
 drawSurface.OnMouseMove:=SelectionMadeMouseMove;
 drawSurface.OnMouseUp:=SelectionMadeMouseUp;

 ge.selected:=true;
 undoer.SaveCreateAction(cUndoGECreate);
 UpdateStatusBar(x,y);
end;

{$REGION 'NewGETextMouse'}
procedure TBMEditorMain.NewGETextMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
 i:integer;
begin
 mouseDownPt:=Point(x,y);
 ScalePointToNative(mouseDownPt.x,mouseDownPt.y,drawSurface.GetScaleAmount);
 leftMouseDownActive:=true;
 if ge.PointInBounds(mouseDownPt) then
  begin
   leftMouseDownActive:=true;
   mouseAtNowPoint:=mouseDownPt;

   i:=ge.PointInResize(mouseDownPt);
   if (i <> -1) or ge.PointInBounds(mouseDownPt) then
    begin
     if (i <> -1) then
      undoer.SaveResizeAction(cUndoGEResize,ge.selectRect.totalRect);
     HandleMouseDownInSelectionRectangle(i);
    end;
   Exit;
  end;

 if ge.selected then    //do we need to end the existing text and start a new one
  EndGETextCreation;

 ge.selectRect.totalRect:=Rect(mouseDownPt.X,mouseDownPt.Y,mouseDownPt.X,mouseDownPt.Y);
 SetGeProperties;
end;

procedure TBMEditorMain.NewGETextMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
 mouseAtNowPointNew:TPoint;
begin
 SelectionMadeMouseMove(sender,shift,x,y);

 if ge.selected then          //moving, resizing it?
  begin
   if not leftMouseDownActive then
    Exit;
  end
 else
  begin
   drawSurface.Paint;
   mouseAtNowPointNew:=Point(x,y);
   ge.selectRect.totalRect.right:=x;
   ge.selectRect.totalRect.bottom:=y;
   ge.selectRect.DrawSelectionRectangle(drawSurface.canvas);     //clear out the old one
   drawSurface.canvas.pen.mode:=pmCopy;                   //restore this setting
  end;

 UpdateStatusBar(x,y);
end;

procedure TBMEditorMain.NewGETextMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
 leftMouseDownActive:=false;
 ValidateRectangle(ge.selectRect.totalRect);

 if ge.moving or ge.resizing then
  begin
   ge.selectRect.index:=-1;
   ge.moving:=false;
   ge.resizing:=false;
   Exit;                   //moving over, not ending creation/editing
  end;

 if IsRectEmpty(ge.selectRect.totalRect) then
  begin
   drawSurface.OnMouseDown:=DrawSurfaceMouseDown;
   drawSurface.OnMouseMove:=DrawSurfaceMouseMove;
   drawSurface.OnMouseUp:=DrawSurfaceMouseUp;
   Exit;
  end;

 ShowHideTextPanel(true);
 ge.selected:=true;
 drawSurface.Invalidate;
end;
{$ENDREGION}

procedure TBMEditorMain.NoFillBtnClick(Sender: TObject);
begin
 if (Sender is TToolButton) then
  brushStlye:=TBrushStyle(TToolButton(sender).Tag);
 if ge.selected then
  begin
   undoer.SaveAttAChangeAction(cUndoGEAttributeChange);
   ge.brushStyle:=brushStlye;
   ge.drawSurface.Invalidate;
  end;
end;

procedure TBMEditorMain.ResizeHorzEditChange(Sender: TObject);
var
 x,y:integer;
begin
 if not (sender is TEdit) then
  Exit;

 if not ResizeMaintainCB.Checked then
  Exit;

 if (ResizeRG.ItemIndex = 0) then
  begin
   case TEdit(sender).Tag of
    0: ResizeVertEdit.Text:=TEdit(sender).Text;
    1: ResizeHorzEdit.Text:=TEdit(sender).Text;
   end;
  end
 else             //pixels
  begin
   try
    BlockResizeChangeEvent(true);
    case TEdit(sender).Tag of
     0:                             //changed the horz so set the vert
      begin
       x:=StrToIntDef(TEdit(sender).Text,0);
       ResizeVertEdit.Text:=IntToStr(Round(x * resizeRec.ratio));
      end;
     1:               //changed the horz so set the vert
      begin
       y:=StrToIntDef(TEdit(sender).Text,0);
       ResizeHorzEdit.Text:=IntToStr(Round(y / resizeRec.ratio));
      end;
    end;
   finally
    BlockResizeChangeEvent(false);
   end;
  end;
end;

procedure TBMEditorMain.ResizeMIClick(Sender: TObject);
begin
 ShowHideRezisePanel(true);
end;

procedure TBMEditorMain.ResizePanelCancelBtnClick(Sender: TObject);
begin
 ShowHideRezisePanel(false);
end;

procedure TBMEditorMain.ResizePanelOKBtnClick(Sender: TObject);

 procedure DoResizePercent;
 var
  x,y,width,height:integer;
 begin
  width:=(resizeRec.inRect.right - resizeRec.inRect.left);
  height:=(resizeRec.inRect.bottom - resizeRec.inRect.top);

//how much do we adjust on the width and height, per side
  x:=Round(width * (1 - (resizeRec.horzValue / 100)) / 2);
  y:=Round(height * (1 - (resizeRec.vertValue / 100)) / 2);

  InflateRect(resizeRec.inRect,-x,-y);                          //modify the rectangle
 end;

 procedure DoResizePixels;
 var
  x,y:integer;
 begin
//how much do we adjust on the width and height, per side
  x:=Round(resizeRec.horzValue / 2);
  y:=Round(resizeRec.vertValue / 2);
  InflateRect(resizeRec.inRect,x,y);                          //modify the rectangle
 end;

begin
 resizeRec.mode:=ResizeRG.ItemIndex;
 resizeRec.keepAspectRatio:=ResizeMaintainCB.Checked;
 resizeRec.horzValue:=StrToIntDef(ResizeHorzEdit.Text,0);
 resizeRec.vertValue:=StrToIntDef(ResizeVertEdit.Text,0);

 if (resizeRec.mode = 0) then
  DoResizePercent
 else
  DoResizePixels;

 if resizeRec.isGE then
  ge.selectRect.totalRect:=resizeRec.inRect
 else
  drawSurface.selectRec.rects.totalRect:=resizeRec.inRect;

 ShowHideRezisePanel(false);
end;

procedure TBMEditorMain.ResizeRGClick(Sender: TObject);
begin
 if (ResizeRG.itemIndex = 1) then
  begin
   try
    BlockResizeChangeEvent(true);
    ResizeHorzEdit.Text:=IntToStr(resizeRec.inRect.Right - resizeRec.inRect.Left);
    ResizeVertEdit.Text:=IntToStr(resizeRec.inRect.Bottom - resizeRec.inRect.Top);
   finally
    BlockResizeChangeEvent(false);
   end;
  end;
end;

procedure TBMEditorMain.RestoreOnMouseKeyEvents;
begin
 leftMouseDownActive:=false;
 drawSurface.OnMouseDown:=DrawSurfaceMouseDown;
 drawSurface.OnMouseMove:=DrawSurfaceMouseMove;
 drawSurface.OnMouseUp:=DrawSurfaceMouseUp;
end;

procedure TBMEditorMain.RotateMIClick(Sender: TObject);
const
 PIDiv180       =  0.017453292519943295769236907684886;
var
 value:string;
 rotatedBitmap:TBitmap;
 spinPoint,newAxis:TPoint;
 rotation,left,top:integer;
 orgRect:TRect;
 orgBMap:TBitmap;
begin
 value:='90';
 if InputQuery('Rotation...', 'Enter a value 1-359',value) then
  begin
   rotation:=EnsureRange(StrToIntDef(value,0),1,359);
   orgBMap:=nil;
   rotatedBitmap:=nil;
   try
    drawSurface.selectRec.Draw(workBM.Canvas);          //restore from selection
    undoer.SaveBitmap(cUndoSaveBM);                     //save for undo
    orgRect:=drawSurface.selectRec.rects.totalRect;     //save size
    orgBMap:=TBitmap.Create;                            //copy bitmap
    orgBMap.Assign(drawSurface.selectRec.bMap);
    orgBMap.PixelFormat:=pf32bit;                       //need 32 bit to rotate
    drawSurface.selectRec.Reset;                        //clear selection values
    FillRectangleWithFillColor(orgRect);                //fill workBM with fill color

    rotatedBitmap:=TBitmap.Create;                      //make bitmap to hold roatated bitmap
    rotatedBitmap.handleType:=bmDIB;
    rotatedBitmap.PixelFormat:=pf32bit;
    spinPoint:=CenterPoint(orgRect);                    //get the center of the existing selection point

    RotateBitmap(orgBMap,rotatedBitmap, -(rotation * PIDiv180),spinPoint,newAxis); //rotate it
    left:=spinPoint.x - (rotatedBitmap.width div 2);           //find new center from old center
    top:=spinPoint.y - (rotatedBitmap.height div 2);
    //set up the select rect record
    drawSurface.selectRec.rects.totalRect:=Rect(left,top,left + rotatedBitmap.Width,top + rotatedBitmap.Height);
    drawSurface.selectRec.active:=true;
    drawSurface.selectRec.bMap.Assign(rotatedBitmap);
    undoer.SaveCreateAction(cUndoSelectCreate);
    drawSurface.Invalidate;
   finally
    orgBMap.Free;
    rotatedBitmap.Free;
    drawSurface.Invalidate;
   end;
  end;
end;

procedure TBMEditorMain.SaveAndExitMIClick(Sender: TObject);
begin
 if ge.selected and not IsRectEmpty(ge.selectRect.totalRect)then
  EndGECreation
 else if drawSurface.selectRec.active then
  drawSurface.selectRec.Draw(workBM.Canvas);

 gSettings.bitmap.Assign(workBM);
 modalResult:=mrOk;
end;

procedure TBMEditorMain.SaveTextStuffToGE;
begin
 ge.fontStyle:=[];
 if BoldCB.Checked then
  Include(ge.fontStyle,fsBold);
 if ItalicCB.Checked then
  Include(ge.fontStyle,fsItalic);
 if UnderlineCB.Checked then
  Include(ge.fontStyle,fsUnderline);
 if StrikeoutCB.Checked then
  Include(ge.fontStyle,fsStrikeOut);

 ge.fontOpaque:=OpaqueCB.Checked;
 ge.fontName:=FontCombo.Text;
 ge.fontSize:=StrToIntDef(FontSizeCombo.Text,8);
 drawSurface.Invalidate;
end;

procedure TBMEditorMain.SelectionMadeMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

 procedure HandleSelectionIsBMSelection;
 var
  i:integer;
 begin
  i:=drawSurface.selectRec.PointInResize(mouseDownPt);
  if (i <> -1) or drawSurface.selectRec.PointInBounds(mouseDownPt) then
   begin
    if (i <> -1) then
     undoer.SaveResizeAction(cUndoSelectResize,drawSurface.selectRec.rects.totalRect);
    HandleMouseDownInSelectionRectangle(i);
   end
  else
   begin                      //end the selection actions
    RestoreOnMouseKeyEvents;
    drawSurface.selectRec.Draw(workBM.Canvas);
    drawSurface.selectRec.Reset;
    drawSurface.Paint;
    drawSurface.OnMouseDown(Sender,Button,Shift,X, Y);
   end;
 end;

 procedure HandleSelectionIsGE;
 var
  i:integer;
 begin
  if not ge.PointInBounds(mouseDownPt) then
   begin
    if ge.selected then
     EndGECreation;

    RestoreOnMouseKeyEvents;
    drawSurface.selectRec.Reset;
    drawSurface.Paint;
    drawSurface.OnMouseDown(Sender,Button,Shift,X, Y);
    Exit;
   end;

  i:=ge.PointInResize(mouseDownPt);
  if (i <> -1) or ge.PointInBounds(mouseDownPt) then
   begin
    if (i <> -1) then
     undoer.SaveResizeAction(cUndoGEResize,ge.selectRect.totalRect);
    HandleMouseDownInSelectionRectangle(i);
   end;
 end;

begin
 mouseDownPt:=Point(x,y);
 ScalePointToNative(mouseDownPt.x,mouseDownPt.y,drawSurface.GetScaleAmount);
 leftMouseDownActive:=true;
//the selection could be a selection of a portion of bitmap or a ge that was just created and
//has not been splatted to the workBM

 if drawSurface.selectRec.active then
  HandleSelectionIsBMSelection
 else if ge.selected then
  HandleSelectionIsGE;
 UpdateStatusBar;
end;

procedure TBMEditorMain.SelectionMadeMouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
var
 mouseAtNowPointNew,diffPt:TPoint;

 procedure IndexToCursor(index:integer);
 begin
  case index of
   0,4:         Screen.Cursor:=crSizeNWSE;
   1,5:         Screen.Cursor:=crSizeNS;
   2,6:         Screen.Cursor:=crSizeNESW;
   3,7:         Screen.Cursor:=crSizeWE;
  end;
 end;

 procedure HandleSelectionIsSelection;
 var
  i:integer;
 begin
  if not (drawSurface.selectRec.resizing or drawSurface.selectRec.moving) then
   if not drawSurface.selectRec.PointInBounds(mouseAtNowPointNew) then
    begin
     Screen.Cursor:=crDefault;
     Exit;
    end;

  if (not leftMouseDownActive) then
   begin                              //if the cursor is set wait for mouse up to reset
    i:=drawSurface.selectRec.PointInResize(mouseAtNowPointNew);
    if (i <> -1) and (drawSurface.selectRec.clipRgn = 0) then
     IndexToCursor(i)
    else
     Screen.Cursor:=crSizeAll;
    drawSurface.selectRec.rects.index:=i;
   end;

  diffPt:=SubtractPoints(mouseAtNowPointNew,mouseAtNowPoint);
  mouseAtNowPoint:=mouseAtNowPointNew;
  if drawSurface.selectRec.moving then
   begin
    if IsRectEmpty(drawSurface.selectRec.rects.totalRect) then       //first time moving
     FillRectangleWithFillColor(drawSurface.selectRec.rects.totalRect);
    drawSurface.selectRec.Move(diffPt.X,diffPt.Y);
    drawSurface.Invalidate;
   end
  else if drawSurface.selectRec.resizing then
   begin
    if (drawSurface.selectRec.clipRgn = 0) then
     ResiseRect(drawSurface.selectRec.rects.index,diffPt,drawSurface.selectRec.rects.totalRect);
    drawSurface.Invalidate;
   end;
 end;

 procedure HandleSelectionIsGE;
 var
  i:integer;
 begin
  if not (ge.resizing or ge.moving) then
   if not ge.PointInBounds(mouseAtNowPointNew) then
    begin
     mouseAtNowPoint:=mouseAtNowPointNew;
     Screen.Cursor:=crDefault;
     Exit;
    end;

  if (not leftMouseDownActive) then
   begin                              //if the cursor is set wait for mouse up to reset
    i:=ge.selectRect.PointInResizeRectangle(mouseAtNowPointNew);
    if (i <> -1) then
     IndexToCursor(i)
    else
     Screen.Cursor:=crSizeAll;
    ge.selectRect.index:=i;
   end;

  if ((ssShift in Shift) and (ge.shapeType in [cLineTool])) then //is the user trying to lock the line
   begin
    if (ge.selectRect.index = 0) then
     LineLocking(ge.selectRect.totalRect.right,ge.selectRect.totalRect.bottom,
                 mouseAtNowPointNew.x,mouseAtNowPointNew.y)
    else
     LineLocking(ge.selectRect.totalRect.left,ge.selectRect.totalRect.top,
                 mouseAtNowPointNew.x,mouseAtNowPointNew.y);
   end;

  if ge.moving then
   begin
    diffPt:=SubtractPoints(mouseAtNowPointNew,mouseAtNowPoint);
    ge.Move(diffPt.X,diffPt.Y);
    drawSurface.Invalidate;
   end
  else if ge.resizing then
   begin
    diffPt:=SubtractPoints(mouseAtNowPoint,mouseAtNowPointNew);
    ge.SelectionRectangleChange(diffPt,Rect(0,0,workBM.Width,workBM.Height));
    ge.ResizeComplete;
    drawSurface.Invalidate;
   end;
  mouseAtNowPoint:=mouseAtNowPointNew;
 end;

begin
 //we could be moving a just created graphic element(ge) or a selected portion of the workBM
 mouseAtNowPointNew:=Point(x,y);
 ScalePointToNative(mouseAtNowPointNew.x,mouseAtNowPointNew.y,drawSurface.GetScaleAmount);

 if drawSurface.selectRec.active then
  HandleSelectionIsSelection
 else if ge.selected then
  HandleSelectionIsGE;
 UpdateStatusBar;
end;

procedure TBMEditorMain.SelectionMadeMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
 aPt:TPoint;
begin
 leftMouseDownActive:=false;
 mouseAtNowPoint:=Point(x,y);
 ScalePointToNative(mouseAtNowPoint.x,mouseAtNowPoint.y,drawSurface.GetScaleAmount);

 aPt:=SubtractPoints(mouseAtNowPoint, mouseDownPt);

 if (ge.shapeType = cLineTool) then
  ValidateLine(ge.selectRect.totalRect)
 else
  ValidateRectangle(drawSurface.selectRec.rects.totalRect);

 if (ge.moving) then
  undoer.SaveMoveAction(cUndoGEMove,aPt)
 else if drawSurface.selectRec.moving then
  undoer.SaveMoveAction(cUndoSelectMove,aPt);

 ge.selectRect.index:=-1;
 ge.moving:=false;
 ge.resizing:=false;

 drawSurface.selectRec.rects.index:=-1;
 drawSurface.selectRec.moving:=false;
 drawSurface.selectRec.resizing:=false;
 drawSurface.Invalidate;
 UpdateStatusBar(mouseAtNowPoint.X,mouseAtNowPoint.Y);
end;

procedure TBMEditorMain.SetFillColor(aColor:TColor);
var
 boundsRect:TRect;
 iconInfo:TIconInfo;
 maskBM,colorBM:TBitmap;
begin
 fillColor:=aColor;

//make the icon for the eraser
 boundsRect:=Rect(12,12,20,20);
 maskBM:=TBitmap.Create;
 colorBM:=TBitmap.Create;
 try
  maskBM.Height:=32;
  maskBM.Width:=32;
  maskBM.Canvas.Brush.Color:=clWhite;
  maskBM.Canvas.FillRect(Rect(0,0,32,32));
  maskBM.Canvas.Brush.Color:=clBlack;
  maskBM.Canvas.FillRect(boundsRect);

  colorBM.Height:=32;
  colorBM.Width:=32;
  colorBM.Canvas.Brush.Color:=clBlack;
  colorBM.Canvas.FillRect(Rect(0,0,32,32));
  colorBM.Canvas.Brush.Color:=fillColor;
  colorBM.Canvas.FillRect(boundsRect);

  iconInfo.fIcon:=false;      //is cursor
  iconInfo.xHotspot:=16;
  iconInfo.yHotspot:=16;
  iconInfo.hbmMask:=maskBM.Handle;
  iconInfo.hbmColor:=colorBM.Handle;
  Screen.Cursors[cEraserCursor]:=CreateIconIndirect(iconInfo);
 finally
  maskBM.Free;
  colorBM.Free;
 end;

end;

procedure TBMEditorMain.SetGeProperties;
begin
 ge.penColor:=penColor;
 ge.fillColor:=fillColor;
 ge.penWidth:=PenWidthCombo.ItemIndex + 1;
 ge.penStyle:=TPenStyle(PenStyleCombo.ItemIndex);
 ge.brushStyle:=brushStlye;
end;

procedure TBMEditorMain.SetSizesForDrawing;
var
 x,y:integer;
 scaleAmount:single;
begin
//the size of the window is reduced by the border and such
 x:=workBM.width;
 y:=workBM.height;

 scaleAmount:=drawSurface.GetScaleAmount;
 drawSurface.top:=0;
 drawSurface.left:=0;
 drawSurface.width:=round(x * scaleAmount);
 drawSurface.height:=round(y * scaleAmount);
end;

procedure TBMEditorMain.TopPanelMouseEnter(Sender: TObject);
begin
 Screen.Cursor:=crDefault;
end;

procedure TBMEditorMain.TextEditCloseBtnClick(Sender: TObject);
begin
 EndGETextCreation;
 ge.selectRect.totalRect:=Rect(mouseDownPt.X,mouseDownPt.Y,mouseDownPt.X,mouseDownPt.Y);
 drawSurface.OnMouseDown:=DrawSurfaceMouseDown;
 drawSurface.OnMouseMove:=DrawSurfaceMouseMove;
 drawSurface.OnMouseUp:=DrawSurfaceMouseUp;
end;

procedure TBMEditorMain.TextMemoEditChange(Sender: TObject);
begin
 ge.text:=TextMemoEdit.Text;
 SaveTextStuffToGE;
end;

procedure TBMEditorMain.SetToolButton(value:integer);
begin
 case value of
 cSelectTool:           SelectBtn.Down:=true;
 cFreeSelectTool:       FreeSelectBtn.Down:=true;
 cPencilTool:           PencilBtn.Down:=true;
 cTextTool:             TextBtn.Down:=true;
 cBucketTool:           BucketBtn.Down:=true;
 cLineTool:             LineToolBtn.Down:=true;
// cZoomTool:             MagnifyBtn.Down:=true;
 cRectangleTool:        RectangleBtn.Down:=true;
 cEraserTool:           EraserBtn.Down:=true;
 cCircleTool:           CircleBtn.Down:=true;
 cDropperTool:          DropperBtn.Down:=true;
 cRoundRectTool:        RoundRectBtn.Down:=true;
 end;
end;

procedure TBMEditorMain.ShowHideRezisePanel(state:boolean);
var
 h,v:integer;
begin
 if state then
  begin
   if ge.selected then
    resizeRec.inRect:=ge.selectRect.totalRect
   else
    resizeRec.inRect:=drawSurface.selectRec.rects.totalRect;

   resizeRec.isGE:=ge.selected;
   h:=(resizeRec.inRect.Right - resizeRec.inRect.Left);
   v:=(resizeRec.inRect.Bottom - resizeRec.inRect.Top);
   if (h = 0) then
    resizeRec.ratio:=1
   else
    resizeRec.ratio:=(v / h);  //initial ratio
   ResizeRG.ItemIndex:=resizeRec.mode;
   try
    BlockResizeChangeEvent(true);
    ResizeHorzEdit.Text:=IntToStr(resizeRec.horzValue);
    ResizeVertEdit.Text:=IntToStr(resizeRec.vertValue);
   finally
    BlockResizeChangeEvent(false);
   end;
   ResizeMaintainCB.Checked:=resizeRec.keepAspectRatio;
   ResizePanel.Width:=185;
   ResizePanel.Visible:=true;           //must be here to make the edit the active control
  end
 else
  begin
   ResizePanel.Visible:=false;
   resizeRec.Reset;
   drawSurface.Invalidate;
  end;
end;

procedure TBMEditorMain.ShowHideTextPanel(state:boolean);
begin
 if state then
  begin
   BoldCB.Checked:=fsBold in ge.fontStyle;
   ItalicCB.Checked:=fsItalic in ge.fontStyle;
   UnderlineCB.Checked:=fsUnderline in ge.fontStyle;
   StrikeoutCB.Checked:=fsStrikeOut in ge.fontStyle;
   OpaqueCB.Checked:=ge.fontOpaque;
   FontCombo.Text:=ge.fontName;
   FontSizeCombo.Text:=IntToStr(ge.fontSize);
   TextMemoEdit.Text:=ge.text;
   TextPanel.Width:=185;
   TextPanel.Visible:=true;           //must be here to make the edit the active control
   ActiveControl:=TextMemoEdit;
  end
 else
  begin
   SaveTextStuffToGE;
   TextPanel.Visible:=false;
  end;
end;

procedure TBMEditorMain.UndoMIClick(Sender: TObject);
begin
 if (Sender is TMenuItem) then
  UndoRedo(TMenuItem(sender).Tag);
end;

procedure TBMEditorMain.UndoRedo(which:integer);
begin
 case which of
  0:undoer.UndoUserAction;
  1:undoer.RedoUserAction;
 end;
end;

procedure TBMEditorMain.UpdateStatusBar(x:integer = 0; y:integer = 0);
var
 aPt:TPoint;
begin
 if ge.selected then
  begin
   BottomBar.Panels[cBBx].Text:=IntToStr(ge.selectRect.totalRect.Left);
   BottomBar.Panels[cBBy].Text:=IntToStr(ge.selectRect.totalRect.Top);
   BottomBar.Panels[cBBw].Text:=IntToStr(ge.selectRect.totalRect.right - ge.selectRect.totalRect.left);
   BottomBar.Panels[cBBh].Text:=IntToStr(ge.selectRect.totalRect.bottom - ge.selectRect.totalRect.top);
  end
 else if drawSurface.selectRec.active then
  begin
   BottomBar.Panels[cBBx].Text:=IntToStr(drawSurface.selectRec.rects.totalRect.Left);
   BottomBar.Panels[cBBy].Text:=IntToStr(drawSurface.selectRec.rects.totalRect.Top);
   BottomBar.Panels[cBBw].Text:=IntToStr(drawSurface.selectRec.rects.totalRect.right -
                                         drawSurface.selectRec.rects.totalRect.left);
   BottomBar.Panels[cBBh].Text:=IntToStr(drawSurface.selectRec.rects.totalRect.bottom -
                                         drawSurface.selectRec.rects.totalRect.top);
  end
 else
  begin
   if not leftMouseDownActive then
    begin                    //moving the mouse around with no editing
     aPt:=Point(x,y);
     ScalePointToNative(aPt.x,aPt.y,drawSurface.GetScaleAmount);
     BottomBar.Panels[cBBx].Text:=IntToStr(aPt.X);
     BottomBar.Panels[cBBy].Text:=IntToStr(aPt.Y);
     BottomBar.Panels[cBBw].Text:='';
     BottomBar.Panels[cBBh].Text:='';
    end
   else
    begin

    end;
  end;

 ZoomLabel.Caption:=drawSurface.GetScalePercent;
end;

procedure TBMEditorMain.ZoomTheViewFinal;
begin                                   //if we are scrolled then the drawing surface gets confused
 MainScrollBox.HorzScrollBar.position:=0;
 MainScrollBox.VertScrollBar.position:=0;
 drawSurface.xForm.eM11:=cScaleRecords[drawSurface.scaleIndex].amount;
 drawSurface.xForm.eM22:=cScaleRecords[drawSurface.scaleIndex].amount;
 SetSizesForDrawing;
 drawSurface.Invalidate;
 MainScrollBox.Update;
 UpdateStatusBar;
end;

procedure TBMEditorMain.ZoomTrackBarChange(Sender: TObject);
begin
 drawSurface.scaleIndex:=ZoomTrackBar.Position;
 ZoomTheViewFinal;
end;

procedure TBMEditorMain.ExitMIClick(Sender: TObject);
begin
 modalResult:=mrClose;
end;

{$REGION 'color paint boxes'}
procedure TBMEditorMain.PenPaintBoxClick(Sender: TObject);
begin
 if not (Sender is TPaintBox) then
  Exit;
 selectedColor:=TPaintBox(sender).Tag;
 PenPaintBox.Invalidate;
 FillPaintBox.Invalidate;
end;

procedure TBMEditorMain.PenPaintBoxPaint(Sender: TObject);
var
 pbRect:TRect;
 pb:TPaintBox;
 boxColor:TColor;

 procedure DrawLabel(s1:string);
 begin
  SetBkColor(pb.Canvas.handle,longword(clBlack));
  SetBkMode(pb.Canvas.handle,TRANSPARENT);
  if pb.Canvas.Brush.Color = cComboColor then
   pb.Canvas.font.color:=clWhite
  else
   pb.Canvas.font.color:=clBlack;
  pb.canvas.font.name:=cOurFont;
  pb.canvas.font.size:=8;
  pb.canvas.font.style:=[];
  pb.Canvas.TextRect(pbRect, s1,[tfCenter,tfBottom,tfSingleLine]);
 end;

begin
 if not (Sender is TPaintBox) then
  Exit;

 pb:=TPaintBox(Sender);
 if (pb.Tag = selectedColor) then
  pb.Canvas.Brush.Color:=cComboColor
 else
  pb.Canvas.Brush.Color:=clWhite;

 pbRect:=Rect(0,0,pb.Width,pb.Height);  //fill background
 InflateRect(pbRect,-2,-2);
 pb.Canvas.Brush.Style:=bsSolid;
 pb.Canvas.FillRect(pbRect);

 pbRect:=Rect(0,0,pb.Width,pb.Height);          //draw a frame
 pb.Canvas.Pen.Color:=clBlack;
 pb.Canvas.Pen.Width:=1;
 pb.Canvas.Pen.Style:=psSolid;
 pb.Canvas.FrameRect(pbRect);

 pbRect:=Rect(0,0,pb.Width,pb.Height - 2);
 if (pb.Tag = 0) then
  begin
   DrawLabel('Pen');
   boxColor:=penColor;
  end
 else
  begin
   DrawLabel('Fill');
   boxColor:=fillColor;
  end;

 pbRect:=Rect(0,0,pb.Width,pb.Height - 12);
 InflateRect(pbRect,-2,-2);
 pb.Canvas.Brush.Color:=boxColor;
 pb.Canvas.Brush.Style:=bsSolid;
 pb.Canvas.FillRect(pbRect);
end;
{$ENDREGION}

procedure TBMEditorMain.FontComboClick(Sender: TObject);
begin
 SaveTextStuffToGE;
end;

procedure TBMEditorMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 gSettings.windowLeft:=Left;
 gSettings.windowTop:=top;
 gSettings.windowWidth:=Width;
 gSettings.windowHeight:=Height;
end;

procedure TBMEditorMain.FormCreate(Sender: TObject);
const
 fontSizes:array[0..15] of string = ('8','9','10','11','12','14','16','18','20','22','24','26','28','36','48','72');
var
 i:integer;
 strList:TStringList;
begin
 ReportMemoryLeaksOnShutdown:= (DebugHook <> 0);
 SelectBtn.Down:=true;
 BrushSolidBtn.Down:=true;
 PenWidthCombo.ItemIndex:=0;
 PenStyleCombo.ItemIndex:=0;
 selectedColor:=0;         //pen
 penColor:=clBlack;
 SetFillColor(clRed);
// gSettings.Initialize;
 undoer:=TUndoController.Create;
 undoer.form:=self;

 SelectBtn.Tag:=cSelectTool;
 FreeSelectBtn.Tag:=cFreeSelectTool;
 PencilBtn.Tag:=cPencilTool;
 TextBtn.Tag:=cTextTool;
 BucketBtn.Tag:=cBucketTool;
 LineToolBtn.Tag:=cLineTool;
// MagnifyBtn.Tag:=cZoomTool;
 RectangleBtn.Tag:=cRectangleTool;
 EraserBtn.Tag:=cEraserTool;
 CircleBtn.Tag:=cCircleTool;
 DropperBtn.Tag:=cDropperTool;
 RoundRectBtn.Tag:=cRoundRectTool;

 self.Left:=gSettings.windowLeft;
 self.Top:=gSettings.windowTop;
 self.Height:=gSettings.windowHeight;
 self.Width:=gSettings.windowWidth;

 workBM:=TBitmap.Create;

 if Assigned(gSettings.bitmap) then
  workBM.Assign(gSettings.bitmap)
 else
  begin
   workBM.Width:=640;
   workBM.Height:=480;
   workBM.PixelFormat:=pf24bit;
  end;

 MainScrollBox.Align:=alClient;
 MainScrollBox.Color:=clSkyBlue;

 drawSurface:=TBMDrawingSurface.Create(MainScrollBox);
 drawSurface.parent:=TWinControl(MainScrollBox);
 drawSurface.SetUp(Width,Height);
 drawSurface.OnMouseDown:=DrawSurfaceMouseDown;
 drawSurface.OnMouseMove:=DrawSurfaceMouseMove;
 drawSurface.OnMouseUp:=DrawSurfaceMouseUp;
 drawSurface.OnKeyDown:=FormKeyDown;
 drawSurface.OnKeyPress:=nil;
 drawSurface.OnKeyUp:=nil;

 ge.bMap:=nil;
 ge.shapeType:=cSelectTool;
 ge.drawSurface:=drawSurface;
 ge.fontName:=cOurFont;
 ge.fontSize:=10;
 ge.fontStyle:=[];
 ge.fontOpaque:=false;
 ge.selectRect.drawingSurface:=drawSurface;

 drawSurface.selectRec.bMap:=nil;
 screen.Cursors[cBuckCursor]:=LoadCursor(HInstance,'BUCKET');

 strList:=GetFontsListSansAmpersand;
 try
  FontCombo.items:=strList;
  FontCombo.items.Add(cOurFont);
  FontCombo.DropDownCount:=32;
  FontCombo.ItemIndex:=FontCombo.Items.IndexOf(cOurFont);
 finally
  strList.Free;
 end;

 for i:=low(fontSizes) to high(fontSizes)do
  FontSizeCombo.Items.Add(fontSizes[i]);
 FontSizeCombo.DropDownCount:=32;

 resizeRec.horzValue:=100;
 resizeRec.vertValue:=100;
 resizeRec.mode:=0;             //percentage
 resizeRec.keepAspectRatio:=true;
 resizeRec.ratio:=1;

 DragAcceptFiles(Handle,True);
 ZoomTrackBar.Position:=3;              //100%
 SetSizesForDrawing;
end;

procedure TBMEditorMain.FormDestroy(Sender: TObject);
begin
 workBM.Free;
 ge.Destroy;
 drawSurface.TearDown;
 undoer.Free;
end;

procedure TBMEditorMain.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
 x,y:integer;
begin
 if ge.selected then
  begin
//when text is editing we want all the keys, except escape, to be handled by the memo
   if (ge.shapeType = cTextTool) and (Key <> VK_ESCAPE) then
    Exit;
   if (ResizePanel.Visible) then
    Exit;

   x:=0;
   y:=0;
   case Key of
    VK_UP:        y:=-1;
    VK_DOWN:      y:=1;
    VK_LEFT:      x:=-1;
    VK_RIGHT:     x:=1;
    VK_DELETE,VK_ESCAPE,VK_BACK:
     begin
      Key:=0;              //no one else needs to handle
      ge.selected:=false;
      Screen.Cursor:=crDefault;
      RestoreOnMouseKeyEvents;
      drawSurface.Invalidate;
      if (ge.shapeType = cTextTool)then
       ShowHideTextPanel(false);
      Exit;
     end;
    else
     Exit;
   end;                         //end of case

   if (GetKeyState(VK_CONTROL) < 0) then
    begin
     x:=(x * 10);
     y:=(y * 10);
    end;
   Key:=0;              //no one else needs to handle
   undoer.SaveMoveAction(cUndoGEMove,Point(x,y));
   OffsetRect(ge.selectRect.totalRect,x,y);
   drawSurface.Invalidate;
   Exit;
  end;                          //end of ge.selected

 if drawSurface.selectRec.active then
  begin
   x:=0;
   y:=0;
   case Key of
    VK_UP:        y:=-1;
    VK_DOWN:      y:=1;
    VK_LEFT:      x:=-1;
    VK_RIGHT:     x:=1;
    VK_DELETE,VK_ESCAPE,VK_BACK:
     begin
      Key:=0;              //no one else needs to handle
      drawSurface.selectRec.Draw(workBM.Canvas);
      drawSurface.selectRec.Reset;
      Screen.Cursor:=crDefault;
      RestoreOnMouseKeyEvents;
      drawSurface.Invalidate;
      Exit;
     end
    else
     Exit;
   end;                         //end of case

   if (GetKeyState(VK_CONTROL) < 0) then
    begin
     x:=(x * 10);
     y:=(y * 10);
    end;
   Key:=0;              //no one else needs to handle
   undoer.SaveMoveAction(cUndoSelectMove,Point(x,y));
   drawSurface.selectRec.Move(x,y);
   drawSurface.Invalidate;
   Exit;
  end;                          //end of ge.selected
end;

procedure TBMEditorMain.FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
var
 aScrollBar:TControlScrollBar;
begin
//if the control key is down scroll the window horz
 if GetKeyState(VK_CONTROL) < 0 then
  aScrollBar:=MainScrollBox.HorzScrollBar
 else
  aScrollBar:=MainScrollBox.VertScrollBar;

 if (WheelDelta > 0) then
  aScrollBar.Position:=aScrollBar.Position - 24
 else
  aScrollBar.Position:=aScrollBar.Position + 24;
 handled:=true;
end;

procedure TBMEditorMain.FormResize(Sender: TObject);
begin
 if Assigned(drawSurface) then
  drawSurface.Invalidate;
end;

procedure TBMEditorMain.FormShow(Sender: TObject);
var
 hSysMenu:HMENU;
begin
 hSysMenu:= GetSystemMenu(self.Handle, False);
 EnableMenuItem(hSysMenu, SC_CLOSE, MF_BYCOMMAND or MF_GRAYED);
end;

procedure TBMEditorMain.PasteMIClick(Sender: TObject);
var
 newBitMap:TBitMap;
begin
 if (ge.selected and (ge.shapeType = cTextTool)) then
  begin
   if Clipboard.HasFormat(CF_TEXT) then
    TextMemoEdit.PasteFromClipboard;
  end
 else if Clipboard.HasFormat(CF_BITMAP) then
  begin
   try
    Clipboard.Open;
    newBitMap:=TBitMap.Create;
    if not Assigned(newBitMap) then
     Exit;

    newBitMap.handleType:=bmDIB;
    newBitMap.Assign(Clipboard);
    if newBitMap.Empty then
     begin
      newBitMap.Free;
      Exit;
     end;

    if ge.selected and not IsRectEmpty(ge.selectRect.totalRect)then
     EndGECreation
    else if drawSurface.selectRec.active then
     begin
      drawSurface.selectRec.Draw(workBM.Canvas);
      drawSurface.selectRec.Reset;
      drawSurface.Paint;
     end;

    if Assigned(ge.bMap) then
     ge.bMap.Free;

    ge.bMap:=newBitMap;
    ge.shapeType:=cBitmapTool;
    ge.selectRect.totalRect:=Rect(0,0,newBitMap.Width,newBitMap.Height);
    ge.selected:=true;
    undoer.SaveCreateAction(cUndoGECreate);

    drawSurface.OnMouseDown:=SelectionMadeMouseDown;
    drawSurface.OnMouseMove:=SelectionMadeMouseMove;
    drawSurface.OnMouseUp:=SelectionMadeMouseUp;
    drawSurface.Invalidate;
   finally
    Clipboard.Close;
   end;
  end
end;

procedure TBMEditorMain.PencilBtnClick(Sender: TObject);
begin
 if drawSurface.selectRec.active then
  drawSurface.selectRec.Draw(workBM.Canvas);

 drawSurface.selectRec.Reset;
 drawSurface.Paint;
 DeSelectAllOnToolBar(SelectToolBar);
 if (Sender is TToolButton) then
  begin
   selectedTool:=TToolButton(sender).Tag;
   TToolButton(sender).Down:=true;
  end;
 RestoreOnMouseKeyEvents;
end;

{$REGION 'Pen Comboboxes'}
procedure TBMEditorMain.PenStyleComboDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
 s1:string;
 cb:TCombobox;
 midPt:integer;
begin
 cb:=Control as TCombobox;
 cb.Canvas.pen.style:=psClear;
 cb.Canvas.brush.Style:=bsSolid;
 cb.Canvas.brush.color:=clWhite;
 cb.Canvas.Rectangle(rect);

//draw the line
 cb.Canvas.pen.width:=1;
 cb.Canvas.pen.color:=clBlack;
 cb.Canvas.pen.style:=psSolid;
 cb.Canvas.pen.style:=TPenStyle(index);
 midPt:=(Rect.bottom + Rect.top) div 2;
 cb.Canvas.MoveTo(Rect.left,midPt);
 cb.Canvas.LineTo(Rect.right,midPt);

//show them if clear with text
 if (cb.Canvas.pen.style in [psClear]) then
  begin
   SetBkColor(cb.Canvas.handle,longword(clBlack));
   SetBkMode(cb.Canvas.handle,TRANSPARENT);
   cb.Canvas.font.color:=clBlack;
   cb.canvas.font.name:=cOurFont;
   cb.canvas.font.size:=8;
   cb.canvas.font.style:=[];
   s1:=cWordClear;
   cb.Canvas.TextRect(rect, s1,[tfCenter, tfVerticalCenter,tfSingleLine])
  end;
 cb.Canvas.pen.style:=psSolid;
end;

procedure TBMEditorMain.PenStyleComboSelect(Sender: TObject);
begin
 if ge.selected then
  begin
   undoer.SaveAttAChangeAction(cUndoGEAttributeChange);
   ge.penStyle:=TPenStyle(PenStyleCombo.ItemIndex);
   ge.drawSurface.Invalidate;
  end;

end;

procedure TBMEditorMain.PenWidthComboDrawItem(Control: TWinControl; Index: Integer;Rect: TRect; State: TOwnerDrawState);
var
 s1:string;
 cb:TCombobox;
 midPt:integer;
begin
 cb:=Control as TCombobox;
 cb.Canvas.pen.style:=psClear;
 cb.Canvas.brush.Style:=bsSolid;
 cb.Canvas.brush.color:=clWhite;
 cb.Canvas.Rectangle(rect);

//draw the line
 cb.Canvas.pen.width:=index + 1;
 cb.Canvas.pen.color:=clBlack;
 cb.Canvas.pen.style:=psSolid;
 midPt:=(Rect.bottom + Rect.top) div 2;
 cb.Canvas.MoveTo(Rect.left,midPt);
 cb.Canvas.LineTo(Rect.right,midPt);

//show the pen size on the left
 SetBkColor(cb.Canvas.handle,longword(clWhite));
 SetBkMode(cb.Canvas.handle,OPAQUE);
 cb.Canvas.font.color:=clBlack;
 cb.canvas.font.name:=cOurFont;
 cb.canvas.font.size:=8;
 cb.canvas.font.style:=[];

 s1:=IntToStr(index + 1) + ' ';
 cb.Canvas.TextRect(rect, s1,[tfLeft, tfVerticalCenter,tfSingleLine]);
end;

procedure TBMEditorMain.PenWidthComboSelect(Sender: TObject);
begin
 if ge.selected then
  begin
   undoer.SaveAttAChangeAction(cUndoGEAttributeChange);
   ge.penWidth:=PenWidthCombo.ItemIndex + 1;
   ge.drawSurface.Invalidate;
  end;
end;
{$ENDREGION}

{$REGION 'Properties panel'}
procedure TBMEditorMain.PropertiesMIClick(Sender: TObject);
begin
 PropertiesPanel.Visible:=true;
 BMHeightEdit.Text:=IntToStr(workBM.Height);
 BMWidthEdit.Text:=IntToStr(workBM.Width);
end;

procedure TBMEditorMain.PropertyCloseBtnClick(Sender: TObject);
var
 w,h:integer;
begin
 w:=StrToIntDef(BMWidthEdit.Text,640);
 h:=StrToIntDef(BMHeightEdit.Text,480);

 if (gSettings.minBitmapWidth <> -1) or (gSettings.maxBitmapWidth <> -1) then
  w:=EnsureRange(w,gSettings.minBitmapWidth,gSettings.maxBitmapWidth);

 if (gSettings.minBitmapHeight <> -1) or (gSettings.maxBitmapHeight <> -1) then
  h:=EnsureRange(h,gSettings.minBitmapHeight,gSettings.maxBitmapHeight);

 if (w > 0) and (h > 0) then
  if (w <> workBM.Width) or (h <> workBM.Height) then
   begin
    workBM.Width:=w;
    workBM.Height:=h;
    drawSurface.Height:=workBM.Height;
    drawSurface.Width:=workBM.Width;
   end;
 PropertiesPanel.Visible:=false;
end;
{$ENDREGION}

procedure TBMEditorMain.SelectallMIClick(Sender: TObject);
begin
 if ge.selected and not IsRectEmpty(ge.selectRect.totalRect)then
  EndGECreation;

 RestoreOnMouseKeyEvents;
 drawSurface.selectRec.Reset;

 drawSurface.selectRec.rects.totalRect:=Rect(0,0,workBM.Width,workBM.Height);
// ScaleRectangleFromNative(drawSurface.selectRec.rects.totalRect,drawSurface.GetScaleAmount);
 selectedTool:=cSelectTool;
 DrawSurfaceMouseUp(nil,mbLeft,[],0,0);
 UpdateStatusBar;
end;

procedure TBMEditorMain.SelectBtnClick(Sender: TObject);
begin
 if ge.selected and not IsRectEmpty(ge.selectRect.totalRect)then
  begin
   EndGECreation;
   drawSurface.Invalidate;
  end;

 if drawSurface.selectRec.active then
  begin
   RestoreOnMouseKeyEvents;
   drawSurface.selectRec.Draw(workBM.Canvas);
   drawSurface.selectRec.Reset;
   drawSurface.Invalidate;
  end;

 DeSelectAllOnToolBar(ToolsBtnBar);
 if (Sender is TToolButton) then
  begin
   selectedTool:=TToolButton(sender).Tag;
   TToolButton(sender).Down:=true;
  end;
 RestoreOnMouseKeyEvents;
end;

{$REGION 'TBMDrawingSurface'}
procedure TBMDrawingSurface.Draw;
begin
 SetScalingIfOn;                        //is the user zooming
 BitBlt(canvas.handle,0,0,BMEditorMain.workBM.width,BMEditorMain.workBM.height,
        BMEditorMain.workBM.canvas.handle,0,0,SRCCOPY);

 if selectRec.active then
  begin
   selectRec.Draw(canvas);
   selectRec.rects.DrawSelectionRectangle(canvas);
   selectRec.rects.DrawSelectionRectangles(canvas);
  end;

 if BMEditorMain.ge.selected then
  begin
   BMEditorMain.ge.Draw(canvas);
   if (BMEditorMain.ge.shapeType = cLineTool) then
    BMEditorMain.ge.selectRect.DrawLineSelectionRectangles(canvas)
   else
    begin
     BMEditorMain.ge.selectRect.DrawSelectionRectangle(canvas);
     BMEditorMain.ge.selectRect.DrawSelectionRectangles(canvas);
    end;
  end;

 SetScalingNormal;               //is the user zooming, then reset
end;

function TBMDrawingSurface.GetScaleAmount:single;
begin
 result:=cScaleRecords[scaleIndex].amount;
end;

function TBMDrawingSurface.GetScalePercent:string;
begin
 result:=cScaleRecords[scaleIndex].percentString + '%';
end;

procedure TBMDrawingSurface.SetPenForpmNotXor(pStyle:TPenStyle = psDot);
begin                                                   //set the pen stuff correct
 canvas.pen.width:=1;
 canvas.pen.style:=pStyle;
 if (pStyle = psDot) then
  canvas.pen.mode:=pmNotXor
 else
  canvas.pen.mode:=pmCopy;

 canvas.pen.color:=clBlack xor clBlack;
 canvas.brush.color:=clWhite;
end;

procedure TBMDrawingSurface.SetScalingIfOn;
begin
 if (scaleIndex <> 3) then
  begin
   SetGraphicsMode(canvas.handle,GM_ADVANCED);
   SetWorldTransform(canvas.handle, xForm);
  end;
end;

procedure TBMDrawingSurface.SetScalingNormal;
begin
 if (scaleIndex <> 3) then
  begin
   SetWorldTransform(canvas.handle,normalxForm);
   SetGraphicsMode(canvas.handle,GM_COMPATIBLE);
  end;
end;

procedure TBMDrawingSurface.SetUp(w,h:integer);
begin
 Color:=clWhite;
 StyleElements:=StyleElements - [seClient];
 BorderStyle:=bsNone;
 Left:=0;
 Top:=0;
 Height:=h;
 Width:=w;
 selectRec.rects.drawingSurface:=Self;

 scaleIndex:=3;
 xForm.eM11:=cScaleRecords[scaleIndex].amount;
 xForm.eM12:=0;
 xForm.eM21:=0;
 xForm.eM22:=cScaleRecords[scaleIndex].amount;
 xForm.eDx:=0;
 xForm.eDy:=0;

//used when we set the world transform back to normal
 normalxForm.eM11:=0;
 normalxForm.eM12:=0;
 normalxForm.eM21:=0;
 normalxForm.eM22:=0;
 normalxForm.eDx:=0;
 normalxForm.eDy:=0;
end;

procedure TBMDrawingSurface.Paint;
begin
 Draw;
end;

procedure TBMDrawingSurface.TearDown;
begin
 if Assigned(selectRec.bMap) then
  selectRec.bMap.Free;
 selectRec.Reset;
end;

procedure TBMDrawingSurface.WmEraseBkgnd(var msg: TWmEraseBkgnd);
begin
 msg.result:=LRESULT(false);                    //stop the flicker
end;
{$ENDREGION}

{$REGION 'geRecord'}
procedure geRecord.Assign(var varRec:geRecord);
begin
 varRec.shapeType:=shapeType;
 if Assigned(bMap) then
  begin
   varRec.bMap:=TBitmap.Create;
   varRec.bMap.Assign(bMap);
  end;
 varRec.penColor:=penColor;
 varRec.fillColor:=fillColor;
 varRec.penWidth:=penWidth;
 varRec.selectRect:=selectRect;
 varRec.penStyle:=penStyle;
 varRec.selected:=selected;
 varRec.moving:=moving;
 varRec.resizing:=resizing;
 varRec.brushStyle:=brushStyle;
 varRec.drawSurface:=drawSurface;
end;

procedure geRecord.Destroy;
begin
 SetLength(pointsArray,0);
 if Assigned(bMap) then
  bMap.Free;
end;

procedure geRecord.Draw(aCanvas: TCanvas);
const
 cTextAlign     = DT_LEFT or DT_NOPREFIX or DT_WORDBREAK or DT_TOP;
var
 s1:string;
begin
 aCanvas.Pen.Color:=penColor;
 aCanvas.Pen.Style:=penStyle;
 aCanvas.Pen.Width:=penWidth;
 aCanvas.Brush.Color:=fillColor;
 aCanvas.Brush.Style:=brushStyle;

 case shapeType of
  cRectangleTool:               aCanvas.Rectangle(selectRect.totalRect);
  cCircleTool:                  aCanvas.Ellipse(selectRect.totalRect);
  cRoundRectTool:               aCanvas.RoundRect(selectRect.totalRect,32,32);
  cLineTool:
   begin
    aCanvas.MoveTo(selectRect.totalRect.left,selectRect.totalRect.top);
    aCanvas.LineTo(selectRect.totalRect.right,selectRect.totalRect.bottom);
   end;
  cPencilTool:
   if Assigned(pointsArray) then
    aCanvas.Polyline(copy(pointsArray,0,pointsCount));
  cTextTool:
   begin
    if selected then
     begin
      aCanvas.Brush.Color:=penColor;
      aCanvas.Pen.Style:=psSolid;
      aCanvas.Pen.Width:=1;
      aCanvas.FrameRect(selectRect.totalRect);
     end;

    if fontOpaque then
     begin
      SetBkMode(aCanvas.handle,OPAQUE);
      aCanvas.pen.Style:=psClear;
      aCanvas.brush.color:=fillColor;     //do not change order of these two
      aCanvas.brush.Style:=brushStyle;    //do not change order of these two
      aCanvas.Rectangle(selectRect.totalRect);
     end
    else
     SetBkMode(aCanvas.handle,TRANSPARENT);

    aCanvas.Font.name:=fontName;
    aCanvas.Font.Size:=fontSize;
    aCanvas.Font.Style:=fontStyle;
    aCanvas.Font.Orientation:=0;
    aCanvas.Font.color:=penColor;
    SetTextColor(aCanvas.handle,longword(penColor));

    if (text = '') then
     s1:='Empty'
    else
     s1:=text;
    DrawText(aCanvas.handle,PChar(s1),length(s1),selectRect.totalRect,cTextAlign);
   end;
  cBitmapTool:
   begin
    if Assigned(bMap) then
     aCanvas.CopyRect(selectRect.totalRect,bMap.Canvas,Rect(0,0,bMap.Width,bMap.Height));
   end;
 end;
end;

procedure geRecord.Move(x,y:integer);
var
 previousRect:TRect;
begin
 previousRect:=selectRect.totalRect;                       //save the rectangle for mapping
 OffsetRect(selectRect.totalRect,x,y);
 if (shapeType = cPencilTool) then
  MapArrayOfPoints(pointsArray,pointsCount,previousRect,selectRect.totalRect); //map all the points of the polygon
end;

function geRecord.PointInBounds(aPt:TPoint):boolean;
var
 testRect:TRect;
 pendWidthDeadband:integer;
begin
 result:=(PointInResize(aPt) <> -1);
 if result then
  Exit;

 if (shapeType = cLineTool) then
  begin
   testRect:=selectRect.totalRect;
   if (testRect.left = testRect.right) then
    begin                                               //we have a vertical line
     pendWidthDeadband:=(aPt.x + (penWidth div 2)) - testRect.left;  //consider the pen width
     result:=(pendWidthDeadband in [0..penWidth]) and
             (aPt.y <= Max(testRect.top,testRect.bottom)) and
             (aPt.y >= Min(testRect.top,testRect.bottom));
     Exit;
    end
   else if (testRect.top = testRect.bottom) then
    begin              //we have a horizontal line
     pendWidthDeadband:=(aPt.y + (penWidth div 2)) - testRect.top;
     result:=(pendWidthDeadband in [0..penWidth]) and
             (aPt.x <= Max(testRect.left,testRect.right)) and
             (aPt.x >= Min(testRect.left,testRect.right));
     Exit;
    end;

   //validate checks left<right, still could be top>bottom
   if (testRect.Top > testRect.Bottom) then
    begin
     if (shapeType = cLineTool) then
      ValidateLine(selectRect.totalRect)
     else
      ValidateRectangle(testRect);
     result:=PtInRect(testRect,aPt);
    end
   else
    result:=TestMouseDownBitmapStyle(aPt.x,aPt.Y);
   Exit;
  end;

 if not IsRectEmpty(selectRect.totalRect) then
  begin
   testRect:=selectRect.totalRect;
   InflateRect(testRect,4,4);
   result:=PtInRect(testRect,aPt);
  end;
end;

function geRecord.PointInResize(aPt:TPoint):integer;
var
 i:integer;
begin
 result:=-1;
 if (shapeType = cLineTool) then
  begin
   if PtInRect(selectRect.edgeRects[0],aPt) then
    result:=0
   else if PtInRect(selectRect.edgeRects[4],aPt) then
    result:=4
  end
 else
  for i:= low(selectRect.edgeRects) to high(selectRect.edgeRects) do
   if PtInRect(selectRect.edgeRects[i],aPt) then
    begin
     result:=i;
     Break;
    end;
end;

procedure geRecord.ResizeComplete;
var
 previousRect:TRect;
begin
 if (shapeType <> cPencilTool) then
  Exit;
 previousRect:=CalculateOutsideRectangleForPolygon(pointsArray,pointsCount);  //get bounding rectangle
 MapArrayOfPoints(pointsArray,pointsCount,previousRect,selectRect.totalRect);
end;

procedure geRecord.SelectionRectangleChange(diffPt:TPoint; boundRect:TRect);

 procedure AdjustBottom;
 var
  x:integer;
 begin
  x:= selectRect.totalRect.bottom - diffPt.y;
  if (x > boundRect.bottom) then
   selectRect.totalRect.bottom:=boundRect.bottom
  else
   selectRect.totalRect.bottom:=x;

//for lines
  if (selectRect.totalRect.bottom < boundRect.top) then
   selectRect.totalRect.bottom:=boundRect.top;
 end;

 procedure AdjustLeft;
 var
  x:integer;
 begin
  x:=selectRect.totalRect.left - diffPt.x;
  if (x < boundRect.left) then
   selectRect.totalRect.left:=boundRect.left
  else
   selectRect.totalRect.left:=x;

//for lines
  if (selectRect.totalRect.left > boundRect.right) then
   selectRect.totalRect.left:=boundRect.right;
 end;

 procedure AdjustRight;
 var
  x:integer;
 begin
  x:=selectRect.totalRect.right - diffPt.x;
  if (x > boundRect.right) then
   selectRect.totalRect.right:=boundRect.right
  else
   selectRect.totalRect.right:=x;

//for lines
  if (selectRect.totalRect.right < boundRect.left) then
   selectRect.totalRect.right:=boundRect.left;
 end;

 procedure AdjustTop;
 var
  x:integer;
 begin
  x:=selectRect.totalRect.top - diffPt.y;
  if (x < boundRect.top) then
   selectRect.totalRect.top:=boundRect.top
  else
   selectRect.totalRect.top:=x;

//for lines
  if (selectRect.totalRect.top > boundRect.bottom) then
   selectRect.totalRect.top:=boundRect.bottom;
 end;

begin
 case selectRect.index of
  0:                    //top left
   begin
    AdjustTop;
    AdjustLeft;
   end;
  1:    AdjustTop;      //top
  2:                    //top right
   begin
    AdjustTop;
    AdjustRight;
   end;
  3:    AdjustRight;    //right
  4:                    //bottom right
   begin
    AdjustBottom;
    AdjustRight;
   end;
  5:    AdjustBottom;   //bottom
  6:                    //bottom left
   begin
    AdjustBottom;
    AdjustLeft;
   end;
  7:    AdjustLeft;     // left
  8:                    //horz center
   begin
    diffPt.x:= (diffPt.x div 2);
    AdjustLeft;
    AdjustRight;
   end;
 end;
end;

function geRecord.TestMouseDownBitmapStyle(x,y:integer):boolean;
var
 bm:TBitMap;
 horzOffset,vertOffset:integer;

 function MousePixelTest(aCanvas:TCanvas; x,y:integer):boolean;
 begin     //this checks a nine pixel square
  result:=(aCanvas.pixels[x - 1,y - 1] = 0) or (aCanvas.pixels[x,y - 1] = 0) or (aCanvas.pixels[x + 1,y - 1] = 0) or
          (aCanvas.pixels[x - 1,y] = 0) or (aCanvas.pixels[x,y] = 0) or (aCanvas.pixels[x,y] = 0) or
          (aCanvas.pixels[x - 1,y + 1] = 0) or (aCanvas.pixels[x,y + 1] = 0) or (aCanvas.pixels[x + 1,y + 1] = 0);
 end;

begin
//we are going to draw the element in a bitmap and test for the a pixel being black
 bm:=nil;
 try
  bm:=TBitMap.Create;
  bm.SetSize(abs(selectRect.totalRect.right - selectRect.totalRect.left),
             abs(selectRect.totalRect.bottom - selectRect.totalRect.top));
  bm.PixelFormat:=pf8bit;

  bm.canvas.brush.color:=clBlack;
  bm.canvas.brush.style:=bsSolid;
  bm.canvas.pen.color:=clBlack;
  bm.canvas.pen.style:=penStyle;
  bm.canvas.pen.width:=penWidth + 3;

  if (selectRect.totalRect.top > selectRect.totalRect.Bottom) then
   vertOffset:=-(selectRect.totalRect.Bottom)
  else
   vertOffset:=-(selectRect.totalRect.top);

  if (selectRect.totalRect.left > selectRect.totalRect.right) then
   horzOffset:=-(selectRect.totalRect.right)
  else
   horzOffset:=-(selectRect.totalRect.left);

  OffsetViewportOrgEx(bm.canvas.handle,horzOffset,vertOffset,nil);
  Draw(bm.canvas);

  result:=MousePixelTest(bm.canvas,x,y);   //is the pixel black
//  bm.canvas.pixels[x,y]:=clRed;
//  bm.SaveToFile('c:\logs\test.bmp');

 finally
  bm.Free;
 end;
end;

procedure geRecord.TransferPolyPointToCanvas(aCanvas:TCanvas);
begin
 if (Length(pointsArray) < 1) then
  Exit;

 Draw(aCanvas);
 SetLength(pointsArray,0);
 pointsCount:=0;
end;

{$ENDREGION}

{$REGION 'seletRectsRec'}
procedure selectRectsRec.DrawLineSelectionRectangles(aCanvas:TCanvas);
begin
 DetermineSelectRectsLine(totalRect,edgeRects);
 SetPenForpmNotXor(aCanvas);
 FrameRectEX(aCanvas,edgeRects[0]);
 FrameRectEX(aCanvas,edgeRects[4]);
 aCanvas.pen.mode:=pmCopy;               //restore this setting
end;

procedure selectRectsRec.DrawSelectionRectangle(aCanvas:TCanvas);
begin
 SetPenForpmNotXor(aCanvas);            //set so can be erased
 aCanvas.Rectangle(totalRect);          //draw the rectangle
 aCanvas.pen.mode:=pmCopy;              //restore this setting
end;

procedure selectRectsRec.DrawSelectionRectangles(aCanvas:TCanvas);
var
 i:integer;
begin
 DetermineSelectRects(totalRect,edgeRects);
 SetPenForpmNotXor(aCanvas);
 for i:= low(edgeRects) to high(edgeRects) do
  FrameRectEX(aCanvas,edgeRects[i]);
 aCanvas.pen.mode:=pmCopy;               //restore this setting
end;

procedure selectRectsRec.GetWidthHeight(var w,h:integer);
begin
 w:=totalRect.right - totalRect.left;
 h:=totalRect.bottom - totalRect.top;
end;

function selectRectsRec.PointInResizeRectangle(aPt:TPoint):integer;
var
 i:integer;
begin
 result:=-1;
 for i:= low(edgeRects) to high(edgeRects) do
  if PtInRect(edgeRects[i],aPt) then
   begin
    result:=i;
    Break;
   end;
end;

function selectRectsRec.PointInTotalRectangle(aPt: TPoint): boolean;
var
 aRect:TRect;
begin
 if IsRectEmpty(totalRect) then
  result:=false
 else
  begin
   aRect:=totalRect;
   InflateRect(aRect,4,4);
   result:=PtInRect(aRect,aPt);
  end;
end;

{$ENDREGION}

{$REGION 'selectionRecord'}
procedure selectionRecord.CopyToBitMapFromCanvas(aCanvas: TCanvas; aRect: TRect);
begin
 if not Assigned(bMap) then
  bMap:=TBitmap.Create
 else
  bMap.SetSize(0,0);

 bMap.SetSize(aRect.Right - aRect.Left,aRect.Bottom - aRect.Top);
 bMap.Canvas.CopyRect(Rect(0,0,bMap.Width,bMap.Height),aCanvas,aRect);
// bMap.SaveToFile('c:\logs\test1.bmp');
end;

procedure selectionRecord.Draw(aCanvas:TCanvas);
var
 transHRGH:HRGN;
 rgnSize,res:integer;
 RegionData:PRgnData;
begin
 if (pointsCount > 0) and (Length(pointsArray) > 0) then
  aCanvas.Polyline(copy(pointsArray,0,pointsCount))
 else if Assigned(bMap) then
  begin
   try
    if (clipRgn <> 0) then
     begin
      if (rects.drawingSurface.scaleIndex <> 3) then    //if scaled the clip region must be duplicated and
       begin                                            //transformed to match the scaling.
        transHRGH:=0;
        rgnSize:=GetRegionData(clipRgn,0,nil);         //get required size
        if (rgnSize = 0) then
         Exit;

        GetMem(RegionData,rgnSize);                    //allocate buffer
        try
         res:=GetRegionData(clipRgn,rgnSize,RegionData);
         if (res <> rgnSize) then        //one help file I read said succes was = 1. Success is as shown.
          Exit;

         transHRGH:=ExtCreateRegion(@rects.drawingSurface.xForm,rgnSize,RegionData^);
         if (transHRGH = 0) then
          Exit;

         SelectClipRgn(aCanvas.Handle,transHRGH);
         aCanvas.Draw(rects.totalRect.Left,rects.totalRect.Top,bMap);

        finally
         FreeMem(RegionData);
         DeleteObject(transHRGH);
        end;

       end
      else
       begin               //if here not zoomed
        SelectClipRgn(aCanvas.Handle,clipRgn);
        aCanvas.Draw(rects.totalRect.Left,rects.totalRect.Top,bMap);
       end;
      end
    else
     aCanvas.CopyRect(rects.totalRect,bMap.Canvas,Rect(0,0,bMap.Width,bMap.Height));
   finally
    if (clipRgn <> 0) then
     SelectClipRgn(aCanvas.Handle,0);
   end;
  end;
end;

procedure selectionRecord.Move(x,y:integer);
begin                                 //not used when is a ge object
 OffsetRect(rects.totalRect,x,y);
 if (clipRgn <> 0) then
  OffsetRgn(clipRgn,x,y);
end;

function selectionRecord.PointInBounds(aPt:TPoint):boolean;
var
 aRect:TRect;
begin
 if IsRectEmpty(rects.totalRect) then
  result:=false
 else
  begin
   aRect:=rects.totalRect;
   InflateRect(aRect,4,4);
   result:=PtInRect(aRect,aPt);
  end;
end;

function selectionRecord.PointInResize(aPt:TPoint):integer;
var
 i:integer;
begin
 result:=-1;
 for i:= low(rects.edgeRects) to high(rects.edgeRects) do
  if PtInRect(rects.edgeRects[i],aPt) then
   begin
    result:=i;
    Break;
   end;
end;

procedure selectionRecord.Reset;
begin
 active:=false;
 rects.index:=-1;
 moving:=false;
 resizing:=false;
 rects.totalRect:=Rect(0,0,0,0);
 ResetPointsVaribles;
 if (clipRgn <> 0) then
  begin
   DeleteObject(clipRgn);
   clipRgn:=0;
  end;
end;

procedure selectionRecord.ResetPointsVaribles;
begin
 SetLength(pointsArray,0);
 pointsCount:=0;
end;
{$ENDREGION}

{$REGION 'TUndoItem'}
destructor TUndoItem.Destroy;
begin
 bMap.Free;
 if (clipRgn <> 0) then
  DeleteObject(clipRgn);
 Inherited;
end;

function TUndoItem.SaveFromGE(ge:geRecord):boolean;
begin
 result:=false;
 shapeType:=ge.shapeType;
 penColor:=ge.penColor;
 fillColor:=ge.fillColor;
 penWidth:=ge.penWidth;
 totalRect:=ge.selectRect.totalRect;
 penStyle:=ge.penStyle;
 brushStyle:=ge.brushStyle;
 if Assigned(ge.bMap) then
  begin
   bMap:=TBitmap.Create;
   if not Assigned(bMap) then
    result:=true
   else
    bMap.Assign(ge.bMap);
  end;
end;

procedure TUndoItem.SaveFromUi(unUI:TUndoItem);
begin
 action:=unUI.action;
 aPt:=unUI.aPt;
 totalRect:=unUI.totalRect;
 redoRect:=unUI.redoRect;

 if Assigned(unUI.bMap) then
  begin
   bMap:=TBitMap.Create;
   bMap.Assign(unUI.bMap);
  end;

 shapeType:=unUI.shapeType;
 penWidth:=unUI.penWidth;
 penStyle:=unUI.penStyle;
 brushStyle:=unUI.brushStyle;
 penColor:=unUI.penColor;
 fillColor:=unUI.fillColor;
end;

procedure TUndoItem.SaveToGE(var ge:geRecord);
begin
 ge.penColor:=penColor;
 ge.fillColor:=fillColor;
 ge.penWidth:=penWidth;
 ge.selectRect.totalRect:=totalRect;
 ge.penStyle:=penStyle;
 ge.brushStyle:=brushStyle;
 ge.selected:=true;
 ge.moving:=false;
 ge.resizing:=false;
end;
{$ENDREGION}

{$REGION 'TUndoController'}
constructor TUndoController.Create;
begin
 undoList:=TList.Create;
 index:=0;
end;

destructor TUndoController.Destroy;
begin
 FreeUndoList;
 Inherited;
end;

procedure TUndoController.FreeUndoList;
var
 i:integer;
begin
 for i:=0 to undoList.Count - 1 do
  TUndoItem(undoList[i]).Free;
 undoList.Free;
end;

procedure TUndoController.PreSaveCheck;
var
 i:integer;
 ui:TUndoItem;
begin
 if (undoList.Count >= gSettings.maxUndoCount) then
  begin
   ui:=TUndoItem(undoList[0]);
   undoList.Delete(0);
   ui.Free;
  end;

 if (index > -1) and (index < undoList.Count) then
  begin       //we are somewhere in the saved chain, user undid and started again, from end to current index
   for i:=undoList.Count - 1 downto index do
    begin
     ui:=TUndoItem(undoList[i]);
     undoList[i]:=nil;
     ui.Free;
    end;
   undoList.Pack;
  end;
end;

procedure TUndoController.RedoUserAction;
var
 ui,tmpUi:TUndoItem;
begin
 if (index >= undoList.Count) then
  Exit;

 ui:=undoList[index];
 Inc(index);
 case ui.action of
  cUndoSelectCreate:
   begin
    form.drawSurface.selectRec.rects.totalRect:=ui.totalRect;
    form.drawSurface.selectRec.active:=true;
    if Assigned(form.drawSurface.selectRec.bMap) then
     form.drawSurface.selectRec.bMap.Free;
    form.drawSurface.selectRec.bMap:=TBitmap.Create;
    if not Assigned(form.drawSurface.selectRec.bMap) then
     Exit;

    form.drawSurface.selectRec.bMap.Assign(ui.bMap);
    form.FillRectangleWithFillColor(ui.totalRect);
    form.selectedTool:=ui.shapeType;
    form.SetToolButton(form.selectedTool);

    form.drawSurface.OnMouseDown:=form.SelectionMadeMouseDown;
    form.drawSurface.OnMouseMove:=form.SelectionMadeMouseMove;
    form.drawSurface.OnMouseUp:=form.SelectionMadeMouseUp;
    form.drawSurface.Invalidate;
   end;
  cUndoSelectMove:
   begin
    form.drawSurface.selectRec.Move(ui.aPt.x,ui.aPt.y);
    form.drawSurface.Invalidate;
   end;
  cUndoGEMove:
   begin
    OffsetRect(form.ge.selectRect.totalRect,ui.aPt.x,ui.aPt.y);
    form.drawSurface.Invalidate;
   end;
  cUndoSelectResize:
   begin
    form.drawSurface.selectRec.rects.totalRect:=ui.redoRect;
    form.drawSurface.Invalidate;
   end;
  cUndoGEResize:
   begin
    form.ge.selectRect.totalRect:=ui.redoRect;
    form.drawSurface.Invalidate;
   end;
  cUndoGECreate:
   begin
    form.ge.shapeType:=ui.shapeType;
    if Assigned(ui.bMap) then
     begin
      if not Assigned(form.ge.bMap) then
       form.ge.bMap:=TBitmap.Create;
      form.ge.bMap.Assign(ui.bMap);
      FreeAndNil(ui.bMap);
     end;
    ui.SaveToGE(form.ge);
    form.drawSurface.OnMouseDown:=form.SelectionMadeMouseDown;
    form.drawSurface.OnMouseMove:=form.SelectionMadeMouseMove;
    form.drawSurface.OnMouseUp:=form.SelectionMadeMouseUp;
    form.drawSurface.Invalidate;
   end;
  cUndoGEAttributeChange:
   begin
    if Assigned(ui.bMap) then
     begin
      if not Assigned(form.ge.bMap) then
       begin
        form.ge.bMap:=TBitmap.Create;
        if not Assigned(form.ge.bMap) then
         Exit;
       end;
      form.ge.bMap.Assign(ui.bMap);
     end;
    ui.SaveToGE(form.ge);
    form.drawSurface.Invalidate;
   end;
  cUndoSaveBM:
   begin
    tmpUi:=TUndoItem.Create;
    try
     tmpUI.bMap:=TBitmap.Create;
     if not Assigned(tmpUI.bMap) then
      Exit;
     tmpUI.bMap.Assign(form.workBM);     //save current bitmap
     form.workBM.Assign(ui.bMap);        //replace with one before
     ui.bMap.Assign(tmpUI.bMap);         //save old bitmap for redo, if needed
     Screen.Cursor:=crDefault;
     form.drawSurface.Invalidate;
    finally
     tmpUi.Free;
    end;
   end;
  cUndoSelectFreeCreate:
   begin
    form.drawSurface.selectRec.rects.totalRect:=ui.totalRect;
    form.drawSurface.selectRec.active:=true;
    if Assigned(form.drawSurface.selectRec.bMap) then
     form.drawSurface.selectRec.bMap.Free;
    form.drawSurface.selectRec.bMap:=TBitmap.Create;
    if not Assigned(form.drawSurface.selectRec.bMap) then
     Exit;

    form.drawSurface.selectRec.bMap.Assign(ui.bMap);
    if (form.drawSurface.selectRec.clipRgn <> 0) then
     DeleteObject(form.drawSurface.selectRec.clipRgn);

    form.drawSurface.selectRec.clipRgn:=DuplicateHRGN(ui.clipRgn);
    SelectClipRgn(form.workBM.Canvas.Handle,ui.clipRgn);
    try
     form.workBM.Canvas.Brush.Style:=ui.brushStyle;
     form.workBM.Canvas.Brush.Color:=ui.fillColor;
     FillRgn(form.workBM.Canvas.Handle,ui.clipRgn,form.workBM.Canvas.Brush.Handle);
    finally
     SelectClipRgn(form.workBM.Canvas.Handle,0);
    end;

    form.selectedTool:=ui.shapeType;
    form.SetToolButton(form.selectedTool);
    form.drawSurface.OnMouseDown:=form.SelectionMadeMouseDown;
    form.drawSurface.OnMouseMove:=form.SelectionMadeMouseMove;
    form.drawSurface.OnMouseUp:=form.SelectionMadeMouseUp;
    form.drawSurface.Invalidate;
   end;
 end;

end;

procedure TUndoController.SaveAttAChangeAction(action:integer);
var
 ui:TUndoItem;
begin
 PreSaveCheck;
 ui:=TUndoItem.Create;
 if not Assigned(ui) then
  Exit;

 ui.action:=action;
 ui.shapeType:=form.ge.shapeType;
 if Assigned(form.ge.bMap) then
  begin
   ui.bMap:=TBitmap.Create;
   if not Assigned(ui.bMap) then
    Exit;
   ui.bMap.Assign(form.ge.bMap);
  end;
 ui.penColor:=form.ge.penColor;
 ui.fillColor:=form.ge.fillColor;
 ui.penWidth:=form.ge.penWidth;
 ui.totalRect:=form.ge.selectRect.totalRect;
 ui.penStyle:=form.ge.penStyle;
 ui.brushStyle:=form.ge.brushStyle;

 undoList.Add(ui);
 Inc(index);
end;

procedure TUndoController.SaveBitmap(action:integer);
var
 ui:TUndoItem;
begin
 ZeroListOfNonBMSave;   //saving bm all other actions are removed, except other BM saves.
 ui:=TUndoItem.Create;
 if not Assigned(ui) then
  Exit;

 ui.action:=action;
 ui.bMap:=TBitmap.Create;
 if not Assigned(ui.bMap) then
  begin
   ui.Free;
   Exit;
  end;
 ui.bMap.Assign(form.workBM);
 undoList.Add(ui);
 Inc(index);
end;

procedure TUndoController.SaveCreateAction(action:integer);
var
 ui:TUndoItem;
begin
 PreSaveCheck;
 ui:=TUndoItem.Create;
 ui.action:=action;

 case action of
  cUndoSelectCreate:
   begin
    ui.totalRect:=form.drawSurface.selectRec.rects.totalRect;
    ui.shapeType:=form.selectedTool;
    ui.fillColor:=form.fillColor;
    ui.bMap:=TBitMap.Create;
    if not Assigned(ui.bMap) then
     begin
      ui.Free;
      Exit;
     end;

    if not Assigned(form.drawSurface.selectRec.bMap) then
     begin
      form.drawSurface.selectRec.bMap:=TBitMap.Create;   //safety
      if not Assigned(form.drawSurface.selectRec.bMap) then
       begin
        ui.Free;
        Exit;
       end;
     end;
    ui.bMap.Assign(form.drawSurface.selectRec.bMap);
   end;
  cUndoGECreate:
   if ui.SaveFromGE(form.ge) then
    begin
     ui.Free;
     Exit;
    end;
  cUndoSelectFreeCreate:    //select create free creates a bitmap with a region
   begin
    if not Assigned(form.drawSurface.selectRec.bMap) or (form.drawSurface.selectRec.clipRgn = 0) then  //safety
     begin
      ui.Free;
      Exit;
     end;

    ui.totalRect:=form.drawSurface.selectRec.rects.totalRect;
    ui.shapeType:=form.selectedTool;
    ui.fillColor:=form.fillColor;
    ui.bMap:=TBitMap.Create;
    if not Assigned(ui.bMap) then
     begin
      ui.Free;
      Exit;
     end;
    ui.bMap.Assign(form.drawSurface.selectRec.bMap);
    ui.clipRgn:=DuplicateHRGN(form.drawSurface.selectRec.clipRgn);
   end;
  else
   begin
    ui.Free;
    Exit;
   end;
 end;                   //end of case

 undoList.Add(ui);
 Inc(index);
end;

procedure TUndoController.SaveMoveAction(action:integer; aPt: TPoint);
var
 ui:TUndoItem;
begin
 PreSaveCheck;
 ui:=TUndoItem.Create;
 if not Assigned(ui) then
  Exit;

 ui.action:=action;
 ui.aPt:=aPt;
 undoList.Add(ui);
 Inc(index);
end;

procedure TUndoController.SaveResizeAction(action:integer; aRect:TRect);
var
 ui:TUndoItem;
begin
 PreSaveCheck;
 ui:=TUndoItem.Create;
 if not Assigned(ui) then
  Exit;

 ui.action:=action;
 ui.totalRect:=aRect;
 undoList.Add(ui);
 Inc(index);
end;

procedure TUndoController.UndoUserAction;
var
 ui,tmpUi:TUndoItem;
begin
 if (index < 0) or (undoList.Count < 0) then
  Exit;

 Dec(index);
 ui:=undoList[index];
 case ui.action of
  cUndoSelectCreate:
   begin
    form.workBM.Canvas.Draw(ui.totalRect.Left,ui.totalRect.Top,ui.bMap);
    form.drawSurface.selectRec.Reset;
    form.RestoreOnMouseKeyEvents;
    Screen.Cursor:=crDefault;
    form.drawSurface.Invalidate;
   end;
  cUndoSelectMove:
   begin
    form.drawSurface.selectRec.Move(-ui.aPt.x,-ui.aPt.y);
    form.drawSurface.Invalidate;
   end;
  cUndoGEMove:
   begin
    OffsetRect(form.ge.selectRect.totalRect,-ui.aPt.x,-ui.aPt.y);
    form.drawSurface.Invalidate;
   end;
  cUndoSelectResize:
   begin
    ui.redoRect:=form.drawSurface.selectRec.rects.totalRect;    //save so can redo if needed
    form.drawSurface.selectRec.rects.totalRect:=ui.totalRect;
    form.drawSurface.Invalidate;
   end;
  cUndoGEResize:
   begin
    ui.redoRect:=form.ge.selectRect.totalRect;                  //save so can redo if needed
    form.ge.selectRect.totalRect:=ui.totalRect;
    form.drawSurface.Invalidate;
   end;
  cUndoGECreate:
   begin
    form.ge.selected:=false;
    form.ge.moving:=false;
    form.ge.resizing:=false;
    if Assigned(form.ge.bMap) then
     FreeAndNil(form.ge.bMap);
    form.RestoreOnMouseKeyEvents;
    Screen.Cursor:=crDefault;
    form.drawSurface.Invalidate;
   end;
  cUndoGEAttributeChange:
   begin
    tmpUi:=TUndoItem.Create;
    try
     tmpUI.shapeType:=form.ge.shapeType;
     tmpUI.penColor:=form.ge.penColor;
     tmpUI.fillColor:=form.ge.fillColor;
     tmpUI.penWidth:=form.ge.penWidth;
     tmpUI.totalRect:=form.ge.selectRect.totalRect;
     tmpUI.penStyle:=form.ge.penStyle;
     tmpUI.brushStyle:=form.ge.brushStyle;
     tmpUI.action:=cUndoGEAttributeChange;
     if Assigned(form.ge.bMap) then
      begin
       tmpUI.bMap:=TBitmap.Create;
       if not Assigned(tmpUI.bMap) then
        Exit;
       tmpUI.bMap.Assign(form.ge.bMap);
      end;

     if Assigned(ui.bMap) then
      begin
       if not Assigned(form.ge.bMap) then
        begin
         form.ge.bMap:=TBitmap.Create;
         if not Assigned(form.ge.bMap) then
          Exit;
        end;
       form.ge.bMap.Assign(ui.bMap);
      end;
     form.ge.penColor:=ui.penColor;
     form.ge.fillColor:=ui.fillColor;
     form.ge.penWidth:=ui.penWidth;
     form.ge.selectRect.totalRect:=ui.totalRect;
     form.ge.penStyle:=ui.penStyle;
     form.ge.brushStyle:=ui.brushStyle;
     ui.SaveFromUi(tmpUi);
     form.drawSurface.Invalidate;
    finally
     tmpUi.Free;
    end;
   end;
  cUndoSaveBM:
   begin
    tmpUi:=TUndoItem.Create;
    try
     tmpUI.bMap:=TBitmap.Create;
     if not Assigned(tmpUI.bMap) then
      Exit;
     tmpUI.bMap.Assign(form.workBM);     //save current bitmap
     form.workBM.Assign(ui.bMap);        //replace with one before
     ui.bMap.Assign(tmpUI.bMap);         //save old bitmap for undo, if needed
     Screen.Cursor:=crDefault;
     form.drawSurface.Invalidate;
    finally
     tmpUi.Free;
    end;
   end;
  cUndoSelectFreeCreate:
   begin
    form.workBM.Canvas.Draw(ui.totalRect.Left,ui.totalRect.Top,ui.bMap);
    form.drawSurface.selectRec.Reset;
    form.RestoreOnMouseKeyEvents;
    Screen.Cursor:=crDefault;
    form.drawSurface.Invalidate;
   end;
 end;
end;

procedure TUndoController.ZeroListOfNonBMSave;
var
 i:integer;
 ui:TUndoItem;
begin
 for i:=0 to undoList.Count - 1 do
  if (TUndoItem(undoList[i]).action <> cUndoSaveBM) then
   begin
    ui:=TUndoItem(undoList[i]);
    ui.Free;
    undoList[i]:=nil;
   end;
 undoList.Pack;
 index:=undoList.Count;
end;
{$ENDREGION}

{$REGION 'resizeRecord'}
procedure resizeRecord.Reset;
begin
 mode:=0;
 horzValue:=100;
 vertValue:=100;
 keepAspectRatio:=true;
end;
{$ENDREGION}

end.
