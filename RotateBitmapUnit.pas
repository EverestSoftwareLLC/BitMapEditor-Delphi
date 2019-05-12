//I got this off the web. Thanks to the guy who wrote it.

{$WARNINGS OFF}
unit RotateBitmapUnit;

interface

uses  Windows,Messages,SysUtils,Classes,Graphics,Controls,forms,StdCtrls,ExtCtrls,
      Math,System.Types;

const degrad: Single = pi/180;

type RealType = Single;
type AngleType = RealType;
type PointType = TPoint;
type CoordType = Integer;
type SiCoDiType = record
 si,co,di:RealType;
end;

procedure RotateBitmap(const BitmapOriginal:TBitMap; out BitmapRotated:TBitMap;
                       const theta:AngleType; const oldAxis:TPOINT;
                       var   newAxis:TPOINT);

implementation


function SiCoDiPoint ( const p1, p2: PointType ): SiCoDiType; {out}
var
 dx, dy: CoordType;
begin
 dx := ( p2.x - p1.x ); 	dy := ( p2.y - p1.y );
 with RESULT do
  begin
   di := HYPOT( dx, dy );
   if abs( di )< 1 then
    begin
     si := 0.0;
     co := 1.0;
    end
   else
    begin
     si := dy/di;
     co := dx/di;
    end;
  end;
end;

procedure RotateBitmap(
 const BitmapOriginal:TBitMap;//input bitmap (possibly converted)
 out   BitMapRotated:TBitMap; //output bitmap
 const theta:AngleType;  // rotn angle in radians counterclockwise in windows
 const oldAxis:TPOINT; 	// center of rotation in pixels, rel to bmp origin
 var   newAxis:TPOINT);  // center of rotated bitmap, relative to bmp origin
		var
		cosTheta       :  Single;   {in windows}
		sinTheta       :  Single;
		i              :  INTEGER;
		iOriginal      :  INTEGER;
		iPrime         :  INTEGER;
		j              :  INTEGER;
		jOriginal      :  INTEGER;
		jPrime         :  INTEGER;
		NewWidth,NewHeight:INTEGER;
		nBytes,nBits: Integer;//no. bytes per pixelformat
		Oht,Owi,Rht,Rwi: Integer;//Original and Rotated subscripts to bottom/right
//The variant pixel formats for subscripting       1/6/00
	type // from Delphi
		TRGBTripleArray = array [0..32767] of TRGBTriple; //allow integer subscript
		pRGBTripleArray = ^TRGBTripleArray;
		TRGBQuadArray = array [0..32767]  of TRGBQuad;//allow integer subscript
		pRGBQuadArray = ^TRGBQuadArray;
	var //each of the following points to the same scanlines
		RowRotatedB: pByteArray; 			//1 byte
		RowRotatedW: pWordArray;  		//2 bytes
		RowRotatedT: pRGBtripleArray;	//3 bytes
		RowRotatedQ: pRGBquadArray;  	//4 bytes
	var //a single pixel for each format 	1/8/00
		TransparentB: Byte;
		TransparentW: Word;
		TransparentT: TRGBTriple;
		TransparentQ: TRGBQuad;
  var
    DIB: TDIBSection;                   //10/31/00
    SiCoPhi: SiCoDiType;                //sine,cosine, distance
    getObjectResult:integer;
{=======================================}
begin

with BitMapOriginal do begin

//Decipher the appropriate pixelformat to use Delphi byte subscripting 1/6/00
//pfDevice, pf1bit, pf4bit, pf8bit, pf15bit, pf16bit, pf24bit, pf32bit,pfCustom;
 case pixelformat of
  pfDevice:
   begin //handle only pixelbits= 1..8,16,24,32 //10/31/00
    nbits :=  GetDeviceCaps( Canvas.Handle,BITSPIXEL ) + 1;
    nbytes := nbits div 8; //no. bytes for bits per pixel
    if (nbytes>0)and(nbits mod 8 <> 0) then
     exit;//ignore if invalid
   end;
  pf1bit:  nBytes:=0;// 1bit, TByteArray      //2 color pallete , re-assign byte value to 8 pixels, for entire scan line
  pf4bit:   nBytes:=0;// 4bit, PByteArray     // 16 color pallette; build nibble for pixel pallette index; convert to 8 pixels
  pf8bit:  nBytes:=1;// 8bit, PByteArray     // byte pallette, 253 out of 256 colors; depends on display mode, needs truecolor ;
  pf15bit: nBytes:=2;// 15bit,PWordArrayType // 0rrrrr ggggg bbbbb  0+5+5+5
  pf16bit: nBytes:=2;// 16bit,PWordArrayType // rrrrr gggggg bbbbb  5+6+5
  pf24bit: nBytes:=3;// 24bit,pRGBtripleArray// bbbbbbbb gggggggg rrrrrrrr  8+8+8
  pf32bit: nBytes:=4;// 32bit,pRGBquadArray  // bbbbbbbb gggggggg rrrrrrrr aaaaaaaa 8+8+8+alpha
  			   // can assign 'Single' reals to this for generating displays/plasma!
  pfCustom:
//MRD
   begin  //handle only pixelbits= 1..8,16,24,32  //10/31/00
    GetObject(Handle,SizeOf(DIB),@DIB); //sometimes this would fail
    if (getObjectResult = SizeOf(DIB)) then
     begin
      nbits:=DIB.dsBmih.biSizeImage;
      nbytes:=(nbits div 8);
      if (nbytes > 0) and (nbits mod 8 <> 0) then
       exit;
     end
    else
     nbytes:=0;
//   Pixelformat := pf8bit;
   end;
//MRD


{ orginial
   begin  //handle only pixelbits= 1..8,16,24,32  //10/31/00
    GetObject( Handle, SizeOf(DIB), @DIB );
    nbits := DIB.dsBmih.biSizeImage;
    nbytes := nbits div 8;
    if (nbytes > 0) and (nbits mod 8 <> 0) then
     exit;//ignore if invalid
   end;// pfcustom }

  else
   exit;// 10/31/00 ignore invalid formats
 end;// case

// BitmapRotated.Pixelformat is the same as BitmapOriginal.Pixelformat;
// if Pixelformat is less than 8 bit, then BitMapOriginal.Pixelformat = pf8Bit,
//  because Delphi can't index to bits, just bytes;
// The next time BitMapOriginal is used it will already be converted.
//( bmp storage may increase by factor of n*n, where n=8/(no. bits per pixel)  )
	if nBytes = 0 then
         Pixelformat := pf8bit; //note that input bmp is changed

//assign copies all properties, including pallette and transparency   11/7/00
//fix bug 1/30/00 where BitMapOriginal was overwritten bec. pointer was copied
  BitmapRotated.Assign(BitMapOriginal);

//COUNTERCLOCKWISE rotation angle in radians. 12/10/99
	 sinTheta := SIN( theta ); cosTheta := COS( theta );
//SINCOS( theta, sinTheta, cosTheta ) ; math.pas requires extended reals.

//calculate the enclosing rectangle  12/15/00
	NewWidth  := ABS( ROUND( Height*sinTheta) ) + ABS( ROUND( Width*cosTheta ) );
	NewHeight := ABS( ROUND( Width*sinTheta ) ) + ABS( ROUND( Height*cosTheta) );

//diff size bitmaps have diff resolution of angle, ie r*sin(theta)<1 pixel
//use the small angle approx: sin(theta) ~~ theta   //11/7/00
  if ( ABS(theta)*MAX( width,height ) ) > 1 then
  begin//non-zero rotation

//set output bitmap formats; we do not assume a fixed format or size 1/6/00
	BitmapRotated.Width  := NewWidth;   //resize it for rotation
	BitmapRotated.Height := NewHeight;

//local constants for loop, each was hit at least width*height times   1/8/00
	Rwi := NewWidth - 1; //right column index
	Rht := NewHeight - 1;//bottom row index
	Owi := Width - 1;    //transp color column index
	Oht := Height - 1;   //transp color row  index

//Transparent pixel color used for out of range pixels 1/8/00
//how to translate a Bitmap.TransparentColor=Canvas.Pixels[0, Height - 1];
// from Tcolor into pixelformat..
	case nBytes of
		0,1:    TransparentB := PByteArray     ( Scanline[ Oht ] )[0];
		2:	TransparentW := PWordArray     ( Scanline[ Oht ] )[0];
		3:	TransparentT := pRGBtripleArray( Scanline[ Oht ] )[0];
		4:	TransparentQ := pRGBquadArray  ( Scanline[ Oht ] )[0];
	end;//case *)

// Step through each row of rotated image.
	for j := Rht downto 0 do   //1/8/00
	begin //for j

		case nBytes of  //1/6/00
		0,1:    RowRotatedB := BitmapRotated.Scanline[ j ] ;
		2:	RowRotatedW := BitmapRotated.Scanline[ j ] ;
		3:	RowRotatedT := BitmapRotated.Scanline[ j ] ;
		4:	RowRotatedQ := BitmapRotated.Scanline[ j ] ;
		end;//case

	// offset origin by the growth factor     //12/25/99
	//	jPrime := 2*(j - (NewHeight - Height) div 2 - jRotationAxis) + 1 ;
		jPrime := 2*j - NewHeight + 1 ;

	// Step through each column of rotated image
		for i := Rwi downto 0 do   //1/8/00
		begin //for i

			// offset origin by the growth factor  //12/25/99
			//iPrime := 2*(i - (NewWidth - Width) div 2 - iRotationAxis ) + 1;
      iPrime := 2*i - NewWidth   + 1;

			// Rotate (iPrime, jPrime) to location of desired pixel	(iPrimeRotated,jPrimeRotated)
			// Transform back to pixel coordinates of image, including translation
			// of origin from axis of rotation to origin of image.
//iOriginal := ( ROUND( iPrime*CosTheta - jPrime*sinTheta ) - 1) div 2 + iRotationAxis;
//jOriginal := ( ROUND( iPrime*sinTheta + jPrime*cosTheta ) - 1) div 2 + jRotationAxis;
			iOriginal := ( ROUND( iPrime*CosTheta - jPrime*sinTheta ) -1 + width ) div 2;
			jOriginal := ( ROUND( iPrime*sinTheta + jPrime*cosTheta ) -1 + height) div 2 ;

			// Make sure (iOriginal, jOriginal) is in BitmapOriginal.  if not,
			// assign background color to corner points.
			if   ( iOriginal >= 0 ) and ( iOriginal <= Owi ) and
					 ( jOriginal >= 0 ) and ( jOriginal <= Oht )    //1/8/00
			then begin //inside
				// Assign pixel from rotated space to current pixel in BitmapRotated
				//( nearest neighbor interpolation)
				case nBytes of  //get pixel bytes according to pixel format   1/6/00
				0,1:    RowRotatedB[i] := pByteArray(      scanline[joriginal] )[iOriginal];
				2:	RowRotatedW[i] := pWordArray(      Scanline[jOriginal] )[iOriginal];
				3:	RowRotatedT[i] := pRGBtripleArray( Scanline[jOriginal] )[iOriginal];
				4:	RowRotatedQ[i] := pRGBquadArray(   Scanline[jOriginal] )[iOriginal];
				end;//case
			end //inside
			else	begin //outside

//12/10/99 set background corner color to transparent (lower left corner)
//	RowRotated[i]:=tpixelformat(BitMapOriginal.TRANSPARENTCOLOR) ; wont work
				case nBytes of
				0,1:    RowRotatedB[i] := TransparentB;
				2:	RowRotatedW[i] := TransparentW;
				3:	RowRotatedT[i] := TransparentT;
				4:	RowRotatedQ[i] := TransparentQ;
				end;//case
			end //if inside

		end //for i
	end;//for j
  end;//non-zero rotation

//offset to the apparent center of rotation   11/12/00 12/25/99
//rotate/translate the old bitmap origin to the new bitmap origin,FIXED 11/12/00
  sicoPhi := sicodiPoint(  POINT( width div 2, height div 2 ),oldaxis );
  //sine/cosine/dist of axis point from center point
  with sicoPhi do begin
//NewAxis := NewCenter + dist* <sin( theta+phi ),cos( theta+phi )>
    NewAxis.x := newWidth div 2 + ROUND( di*(CosTheta * co - SinTheta*si) );
    NewAxis.y := newHeight div 2- ROUND( di*(SinTheta * co + CosTheta*si) );//flip yaxis
  end;

end;//with

end; {RotateImage}

end.
{$WARNINGS ON}
