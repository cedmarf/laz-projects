//----------------------------------------------------------------------------
// Anti-Grain Geometry - Version 2.4 (Public License)
// Copyright (C) 2002-2005 Maxim Shemanarev (http://www.antigrain.com)
//
// Anti-Grain Geometry - Version 2.4 Release Milano 3 (AggPas 2.4 RM3)
// Pascal Port By: Milan Marusinec alias Milano
//                 milan@marusinec.sk
//                 http://www.aggpas.org
// Copyright (c) 2005-2006
//
// Permission to copy, use, modify, sell and distribute this software
// is granted provided this copyright notice appears in all copies.
// This software is provided "as is" without express or implied
// warranty, and with no claim as to its suitability for any purpose.
//
//----------------------------------------------------------------------------
// Contact: mcseem@antigrain.com
//          mcseemagg@yahoo.com
//          http://www.antigrain.com
//
// [Pascal Port History] -----------------------------------------------------
//
// 23.06.2006-Milano: ptrcomp adjustments
// 21.12.2005-Milano: Unit port establishment
//
{ agg_gsv_text.pas }
unit
 agg_gsv_text ;

INTERFACE

{$I agg_mode.inc }
{$Q- }
{$R- }
uses
 SysUtils ,
 agg_basics ,
 agg_vertex_source ,
 agg_conv_stroke ,
 agg_conv_transform ,
 agg_trans_affine ,
 agg_math_stroke ;

{ TYPES DEFINITION }
type
 status = (
  initial,
  next_char,
  start_glyph,
  glyph );

//---------------------------------------------------------------gsv_text
 gsv_text_ptr = ^gsv_text;
 gsv_text = object(vertex_source )
   m_x           ,
   m_y           ,
   m_start_x     ,
   m_width       ,
   m_height      ,
   m_space       ,
   m_line_space  : double;
   m_chr         : array[0..1 ] of byte;
   m_text        ,
   m_text_buf    : pointer;
   m_buf_size    : unsigned;
   m_cur_chr     : int8u_ptr;
   m_font        ,
   m_loaded_font : pointer;
   m_loadfont_sz : unsigned;
   m_status      : status;
   m_big_endian  ,
   m_flip        : boolean;

   m_indices : int8u_ptr;
   m_glyphs  ,
   m_bglyph  ,
   m_eglyph  : int8_ptr;
   m_w       ,
   m_h       : double;

   constructor Construct;
   destructor  Destruct; virtual;

   procedure font_       (font : pointer );
   procedure flip_       (flip_y : boolean );
   procedure load_font_  (_file_ : shortstring );
   procedure size_       (height : double; width : double = 0.0 );
   procedure space_      (space : double );
   procedure line_space_ (line_space : double );
   procedure start_point_(x ,y : double );
   procedure text_       (text : char_ptr );

   procedure rewind(path_id : unsigned ); virtual;
   function  vertex(x ,y : double_ptr ) : unsigned; virtual;

   function  _value(p : int8u_ptr ) : int16u;

  end;

//--------------------------------------------------------gsv_text_outline
 gsv_text_outline = object(vertex_source )
   m_polyline : conv_stroke;
   m_trans    : conv_transform;

   constructor Construct(text : gsv_text_ptr; trans : trans_affine_ptr );
   destructor  Destruct; virtual;

   procedure width_(w : double );

   procedure transformer_(trans : trans_affine_ptr );

   procedure rewind(path_id : unsigned ); virtual;
   function  vertex(x ,y : double_ptr ) : unsigned; virtual;

  end;

{ GLOBAL PROCEDURES }


IMPLEMENTATION
{ LOCAL VARIABLES & CONSTANTS }
const
 gsv_default_font : array[0..4525 ] of int8u = (
  $40,$00,$6c,$0f,$15,$00,$0e,$00,$f9,$ff,
  $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
  $0d,$0a,$0d,$0a,$46,$6f,$6e,$74,$20,$28,
  $63,$29,$20,$4d,$69,$63,$72,$6f,$50,$72,
  $6f,$66,$20,$32,$37,$20,$53,$65,$70,$74,
  $65,$6d,$62,$2e,$31,$39,$38,$39,$00,$0d,
  $0a,$0d,$0a,$00,$00,$00,$00,$00,$00,$00,
  $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
  $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
  $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
  $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
  $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
  $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
  $02,$00,$12,$00,$34,$00,$46,$00,$94,$00,
  $d0,$00,$2e,$01,$3e,$01,$64,$01,$8a,$01,
  $98,$01,$a2,$01,$b4,$01,$ba,$01,$c6,$01,
  $cc,$01,$f0,$01,$fa,$01,$18,$02,$38,$02,
  $44,$02,$68,$02,$98,$02,$a2,$02,$de,$02,
  $0e,$03,$24,$03,$40,$03,$48,$03,$52,$03,
  $5a,$03,$82,$03,$ec,$03,$fa,$03,$26,$04,
  $4c,$04,$6a,$04,$7c,$04,$8a,$04,$b6,$04,
  $c4,$04,$ca,$04,$e0,$04,$ee,$04,$f8,$04,
  $0a,$05,$18,$05,$44,$05,$5e,$05,$8e,$05,
  $ac,$05,$d6,$05,$e0,$05,$f6,$05,$00,$06,
  $12,$06,$1c,$06,$28,$06,$36,$06,$48,$06,
  $4e,$06,$60,$06,$6e,$06,$74,$06,$84,$06,
  $a6,$06,$c8,$06,$e6,$06,$08,$07,$2c,$07,
  $3c,$07,$68,$07,$7c,$07,$8c,$07,$a2,$07,
  $b0,$07,$b6,$07,$d8,$07,$ec,$07,$10,$08,
  $32,$08,$54,$08,$64,$08,$88,$08,$98,$08,
  $ac,$08,$b6,$08,$c8,$08,$d2,$08,$e4,$08,
  $f2,$08,$3e,$09,$48,$09,$94,$09,$c2,$09,
  $c4,$09,$d0,$09,$e2,$09,$04,$0a,$0e,$0a,
  $26,$0a,$34,$0a,$4a,$0a,$66,$0a,$70,$0a,
  $7e,$0a,$8e,$0a,$9a,$0a,$a6,$0a,$b4,$0a,
  $d8,$0a,$e2,$0a,$f6,$0a,$18,$0b,$22,$0b,
  $32,$0b,$56,$0b,$60,$0b,$6e,$0b,$7c,$0b,
  $8a,$0b,$9c,$0b,$9e,$0b,$b2,$0b,$c2,$0b,
  $d8,$0b,$f4,$0b,$08,$0c,$30,$0c,$56,$0c,
  $72,$0c,$90,$0c,$b2,$0c,$ce,$0c,$e2,$0c,
  $fe,$0c,$10,$0d,$26,$0d,$36,$0d,$42,$0d,
  $4e,$0d,$5c,$0d,$78,$0d,$8c,$0d,$8e,$0d,
  $90,$0d,$92,$0d,$94,$0d,$96,$0d,$98,$0d,
  $9a,$0d,$9c,$0d,$9e,$0d,$a0,$0d,$a2,$0d,
  $a4,$0d,$a6,$0d,$a8,$0d,$aa,$0d,$ac,$0d,
  $ae,$0d,$b0,$0d,$b2,$0d,$b4,$0d,$b6,$0d,
  $b8,$0d,$ba,$0d,$bc,$0d,$be,$0d,$c0,$0d,
  $c2,$0d,$c4,$0d,$c6,$0d,$c8,$0d,$ca,$0d,
  $cc,$0d,$ce,$0d,$d0,$0d,$d2,$0d,$d4,$0d,
  $d6,$0d,$d8,$0d,$da,$0d,$dc,$0d,$de,$0d,
  $e0,$0d,$e2,$0d,$e4,$0d,$e6,$0d,$e8,$0d,
  $ea,$0d,$ec,$0d,$0c,$0e,$26,$0e,$48,$0e,
  $64,$0e,$88,$0e,$92,$0e,$a6,$0e,$b4,$0e,
  $d0,$0e,$ee,$0e,$02,$0f,$16,$0f,$26,$0f,
  $3c,$0f,$58,$0f,$6c,$0f,$6c,$0f,$6c,$0f,
  $6c,$0f,$6c,$0f,$6c,$0f,$6c,$0f,$6c,$0f,
  $6c,$0f,$6c,$0f,$6c,$0f,$6c,$0f,$6c,$0f,
  $6c,$0f,$6c,$0f,$6c,$0f,$6c,$0f,$10,$80,
  $05,$95,$00,$72,$00,$fb,$ff,$7f,$01,$7f,
  $01,$01,$ff,$01,$05,$fe,$05,$95,$ff,$7f,
  $00,$7a,$01,$86,$ff,$7a,$01,$87,$01,$7f,
  $fe,$7a,$0a,$87,$ff,$7f,$00,$7a,$01,$86,
  $ff,$7a,$01,$87,$01,$7f,$fe,$7a,$05,$f2,
  $0b,$95,$f9,$64,$0d,$9c,$f9,$64,$fa,$91,
  $0e,$00,$f1,$fa,$0e,$00,$04,$fc,$08,$99,
  $00,$63,$04,$9d,$00,$63,$04,$96,$ff,$7f,
  $01,$7f,$01,$01,$00,$01,$fe,$02,$fd,$01,
  $fc,$00,$fd,$7f,$fe,$7e,$00,$7e,$01,$7e,
  $01,$7f,$02,$7f,$06,$7e,$02,$7f,$02,$7e,
  $f2,$89,$02,$7e,$02,$7f,$06,$7e,$02,$7f,
  $01,$7f,$01,$7e,$00,$7c,$fe,$7e,$fd,$7f,
  $fc,$00,$fd,$01,$fe,$02,$00,$01,$01,$01,
  $01,$7f,$ff,$7f,$10,$fd,$15,$95,$ee,$6b,
  $05,$95,$02,$7e,$00,$7e,$ff,$7e,$fe,$7f,
  $fe,$00,$fe,$02,$00,$02,$01,$02,$02,$01,
  $02,$00,$02,$7f,$03,$7f,$03,$00,$03,$01,
  $02,$01,$fc,$f2,$fe,$7f,$ff,$7e,$00,$7e,
  $02,$7e,$02,$00,$02,$01,$01,$02,$00,$02,
  $fe,$02,$fe,$00,$07,$f9,$15,$8d,$ff,$7f,
  $01,$7f,$01,$01,$00,$01,$ff,$01,$ff,$00,
  $ff,$7f,$ff,$7e,$fe,$7b,$fe,$7d,$fe,$7e,
  $fe,$7f,$fd,$00,$fd,$01,$ff,$02,$00,$03,
  $01,$02,$06,$04,$02,$02,$01,$02,$00,$02,
  $ff,$02,$fe,$01,$fe,$7f,$ff,$7e,$00,$7e,
  $01,$7d,$02,$7d,$05,$79,$02,$7e,$03,$7f,
  $01,$00,$01,$01,$00,$01,$f1,$fe,$fe,$01,
  $ff,$02,$00,$03,$01,$02,$02,$02,$00,$86,
  $01,$7e,$08,$75,$02,$7e,$02,$7f,$05,$80,
  $05,$93,$ff,$01,$01,$01,$01,$7f,$00,$7e,
  $ff,$7e,$ff,$7f,$06,$f1,$0b,$99,$fe,$7e,
  $fe,$7d,$fe,$7c,$ff,$7b,$00,$7c,$01,$7b,
  $02,$7c,$02,$7d,$02,$7e,$fe,$9e,$fe,$7c,
  $ff,$7d,$ff,$7b,$00,$7c,$01,$7b,$01,$7d,
  $02,$7c,$05,$85,$03,$99,$02,$7e,$02,$7d,
  $02,$7c,$01,$7b,$00,$7c,$ff,$7b,$fe,$7c,
  $fe,$7d,$fe,$7e,$02,$9e,$02,$7c,$01,$7d,
  $01,$7b,$00,$7c,$ff,$7b,$ff,$7d,$fe,$7c,
  $09,$85,$08,$95,$00,$74,$fb,$89,$0a,$7a,
  $00,$86,$f6,$7a,$0d,$f4,$0d,$92,$00,$6e,
  $f7,$89,$12,$00,$04,$f7,$06,$81,$ff,$7f,
  $ff,$01,$01,$01,$01,$7f,$00,$7e,$ff,$7e,
  $ff,$7f,$06,$84,$04,$89,$12,$00,$04,$f7,
  $05,$82,$ff,$7f,$01,$7f,$01,$01,$ff,$01,
  $05,$fe,$00,$fd,$0e,$18,$00,$eb,$09,$95,
  $fd,$7f,$fe,$7d,$ff,$7b,$00,$7d,$01,$7b,
  $02,$7d,$03,$7f,$02,$00,$03,$01,$02,$03,
  $01,$05,$00,$03,$ff,$05,$fe,$03,$fd,$01,
  $fe,$00,$0b,$eb,$06,$91,$02,$01,$03,$03,
  $00,$6b,$09,$80,$04,$90,$00,$01,$01,$02,
  $01,$01,$02,$01,$04,$00,$02,$7f,$01,$7f,
  $01,$7e,$00,$7e,$ff,$7e,$fe,$7d,$f6,$76,
  $0e,$00,$03,$80,$05,$95,$0b,$00,$fa,$78,
  $03,$00,$02,$7f,$01,$7f,$01,$7d,$00,$7e,
  $ff,$7d,$fe,$7e,$fd,$7f,$fd,$00,$fd,$01,
  $ff,$01,$ff,$02,$11,$fc,$0d,$95,$f6,$72,
  $0f,$00,$fb,$8e,$00,$6b,$07,$80,$0f,$95,
  $f6,$00,$ff,$77,$01,$01,$03,$01,$03,$00,
  $03,$7f,$02,$7e,$01,$7d,$00,$7e,$ff,$7d,
  $fe,$7e,$fd,$7f,$fd,$00,$fd,$01,$ff,$01,
  $ff,$02,$11,$fc,$10,$92,$ff,$02,$fd,$01,
  $fe,$00,$fd,$7f,$fe,$7d,$ff,$7b,$00,$7b,
  $01,$7c,$02,$7e,$03,$7f,$01,$00,$03,$01,
  $02,$02,$01,$03,$00,$01,$ff,$03,$fe,$02,
  $fd,$01,$ff,$00,$fd,$7f,$fe,$7e,$ff,$7d,
  $10,$f9,$11,$95,$f6,$6b,$fc,$95,$0e,$00,
  $03,$eb,$08,$95,$fd,$7f,$ff,$7e,$00,$7e,
  $01,$7e,$02,$7f,$04,$7f,$03,$7f,$02,$7e,
  $01,$7e,$00,$7d,$ff,$7e,$ff,$7f,$fd,$7f,
  $fc,$00,$fd,$01,$ff,$01,$ff,$02,$00,$03,
  $01,$02,$02,$02,$03,$01,$04,$01,$02,$01,
  $01,$02,$00,$02,$ff,$02,$fd,$01,$fc,$00,
  $0c,$eb,$10,$8e,$ff,$7d,$fe,$7e,$fd,$7f,
  $ff,$00,$fd,$01,$fe,$02,$ff,$03,$00,$01,
  $01,$03,$02,$02,$03,$01,$01,$00,$03,$7f,
  $02,$7e,$01,$7c,$00,$7b,$ff,$7b,$fe,$7d,
  $fd,$7f,$fe,$00,$fd,$01,$ff,$02,$10,$fd,
  $05,$8e,$ff,$7f,$01,$7f,$01,$01,$ff,$01,
  $00,$f4,$ff,$7f,$01,$7f,$01,$01,$ff,$01,
  $05,$fe,$05,$8e,$ff,$7f,$01,$7f,$01,$01,
  $ff,$01,$01,$f3,$ff,$7f,$ff,$01,$01,$01,
  $01,$7f,$00,$7e,$ff,$7e,$ff,$7f,$06,$84,
  $14,$92,$f0,$77,$10,$77,$04,$80,$04,$8c,
  $12,$00,$ee,$fa,$12,$00,$04,$fa,$04,$92,
  $10,$77,$f0,$77,$14,$80,$03,$90,$00,$01,
  $01,$02,$01,$01,$02,$01,$04,$00,$02,$7f,
  $01,$7f,$01,$7e,$00,$7e,$ff,$7e,$ff,$7f,
  $fc,$7e,$00,$7d,$00,$fb,$ff,$7f,$01,$7f,
  $01,$01,$ff,$01,$09,$fe,$12,$8d,$ff,$02,
  $fe,$01,$fd,$00,$fe,$7f,$ff,$7f,$ff,$7d,
  $00,$7d,$01,$7e,$02,$7f,$03,$00,$02,$01,
  $01,$02,$fb,$88,$fe,$7e,$ff,$7d,$00,$7d,
  $01,$7e,$01,$7f,$07,$8b,$ff,$78,$00,$7e,
  $02,$7f,$02,$00,$02,$02,$01,$03,$00,$02,
  $ff,$03,$ff,$02,$fe,$02,$fe,$01,$fd,$01,
  $fd,$00,$fd,$7f,$fe,$7f,$fe,$7e,$ff,$7e,
  $ff,$7d,$00,$7d,$01,$7d,$01,$7e,$02,$7e,
  $02,$7f,$03,$7f,$03,$00,$03,$01,$02,$01,
  $01,$01,$fe,$8d,$ff,$78,$00,$7e,$01,$7f,
  $08,$fb,$09,$95,$f8,$6b,$08,$95,$08,$6b,
  $f3,$87,$0a,$00,$04,$f9,$04,$95,$00,$6b,
  $00,$95,$09,$00,$03,$7f,$01,$7f,$01,$7e,
  $00,$7e,$ff,$7e,$ff,$7f,$fd,$7f,$f7,$80,
  $09,$00,$03,$7f,$01,$7f,$01,$7e,$00,$7d,
  $ff,$7e,$ff,$7f,$fd,$7f,$f7,$00,$11,$80,
  $12,$90,$ff,$02,$fe,$02,$fe,$01,$fc,$00,
  $fe,$7f,$fe,$7e,$ff,$7e,$ff,$7d,$00,$7b,
  $01,$7d,$01,$7e,$02,$7e,$02,$7f,$04,$00,
  $02,$01,$02,$02,$01,$02,$03,$fb,$04,$95,
  $00,$6b,$00,$95,$07,$00,$03,$7f,$02,$7e,
  $01,$7e,$01,$7d,$00,$7b,$ff,$7d,$ff,$7e,
  $fe,$7e,$fd,$7f,$f9,$00,$11,$80,$04,$95,
  $00,$6b,$00,$95,$0d,$00,$f3,$f6,$08,$00,
  $f8,$f5,$0d,$00,$02,$80,$04,$95,$00,$6b,
  $00,$95,$0d,$00,$f3,$f6,$08,$00,$06,$f5,
  $12,$90,$ff,$02,$fe,$02,$fe,$01,$fc,$00,
  $fe,$7f,$fe,$7e,$ff,$7e,$ff,$7d,$00,$7b,
  $01,$7d,$01,$7e,$02,$7e,$02,$7f,$04,$00,
  $02,$01,$02,$02,$01,$02,$00,$03,$fb,$80,
  $05,$00,$03,$f8,$04,$95,$00,$6b,$0e,$95,
  $00,$6b,$f2,$8b,$0e,$00,$04,$f5,$04,$95,
  $00,$6b,$04,$80,$0c,$95,$00,$70,$ff,$7d,
  $ff,$7f,$fe,$7f,$fe,$00,$fe,$01,$ff,$01,
  $ff,$03,$00,$02,$0e,$f9,$04,$95,$00,$6b,
  $0e,$95,$f2,$72,$05,$85,$09,$74,$03,$80,
  $04,$95,$00,$6b,$00,$80,$0c,$00,$01,$80,
  $04,$95,$00,$6b,$00,$95,$08,$6b,$08,$95,
  $f8,$6b,$08,$95,$00,$6b,$04,$80,$04,$95,
  $00,$6b,$00,$95,$0e,$6b,$00,$95,$00,$6b,
  $04,$80,$09,$95,$fe,$7f,$fe,$7e,$ff,$7e,
  $ff,$7d,$00,$7b,$01,$7d,$01,$7e,$02,$7e,
  $02,$7f,$04,$00,$02,$01,$02,$02,$01,$02,
  $01,$03,$00,$05,$ff,$03,$ff,$02,$fe,$02,
  $fe,$01,$fc,$00,$0d,$eb,$04,$95,$00,$6b,
  $00,$95,$09,$00,$03,$7f,$01,$7f,$01,$7e,
  $00,$7d,$ff,$7e,$ff,$7f,$fd,$7f,$f7,$00,
  $11,$f6,$09,$95,$fe,$7f,$fe,$7e,$ff,$7e,
  $ff,$7d,$00,$7b,$01,$7d,$01,$7e,$02,$7e,
  $02,$7f,$04,$00,$02,$01,$02,$02,$01,$02,
  $01,$03,$00,$05,$ff,$03,$ff,$02,$fe,$02,
  $fe,$01,$fc,$00,$03,$ef,$06,$7a,$04,$82,
  $04,$95,$00,$6b,$00,$95,$09,$00,$03,$7f,
  $01,$7f,$01,$7e,$00,$7e,$ff,$7e,$ff,$7f,
  $fd,$7f,$f7,$00,$07,$80,$07,$75,$03,$80,
  $11,$92,$fe,$02,$fd,$01,$fc,$00,$fd,$7f,
  $fe,$7e,$00,$7e,$01,$7e,$01,$7f,$02,$7f,
  $06,$7e,$02,$7f,$01,$7f,$01,$7e,$00,$7d,
  $fe,$7e,$fd,$7f,$fc,$00,$fd,$01,$fe,$02,
  $11,$fd,$08,$95,$00,$6b,$f9,$95,$0e,$00,
  $01,$eb,$04,$95,$00,$71,$01,$7d,$02,$7e,
  $03,$7f,$02,$00,$03,$01,$02,$02,$01,$03,
  $00,$0f,$04,$eb,$01,$95,$08,$6b,$08,$95,
  $f8,$6b,$09,$80,$02,$95,$05,$6b,$05,$95,
  $fb,$6b,$05,$95,$05,$6b,$05,$95,$fb,$6b,
  $07,$80,$03,$95,$0e,$6b,$00,$95,$f2,$6b,
  $11,$80,$01,$95,$08,$76,$00,$75,$08,$95,
  $f8,$76,$09,$f5,$11,$95,$f2,$6b,$00,$95,
  $0e,$00,$f2,$eb,$0e,$00,$03,$80,$03,$93,
  $00,$6c,$01,$94,$00,$6c,$ff,$94,$05,$00,
  $fb,$ec,$05,$00,$02,$81,$00,$95,$0e,$68,
  $00,$83,$06,$93,$00,$6c,$01,$94,$00,$6c,
  $fb,$94,$05,$00,$fb,$ec,$05,$00,$03,$81,
  $03,$87,$08,$05,$08,$7b,$f0,$80,$08,$04,
  $08,$7c,$03,$f9,$01,$80,$10,$00,$01,$80,
  $06,$95,$ff,$7f,$ff,$7e,$00,$7e,$01,$7f,
  $01,$01,$ff,$01,$05,$ef,$0f,$8e,$00,$72,
  $00,$8b,$fe,$02,$fe,$01,$fd,$00,$fe,$7f,
  $fe,$7e,$ff,$7d,$00,$7e,$01,$7d,$02,$7e,
  $02,$7f,$03,$00,$02,$01,$02,$02,$04,$fd,
  $04,$95,$00,$6b,$00,$8b,$02,$02,$02,$01,
  $03,$00,$02,$7f,$02,$7e,$01,$7d,$00,$7e,
  $ff,$7d,$fe,$7e,$fe,$7f,$fd,$00,$fe,$01,
  $fe,$02,$0f,$fd,$0f,$8b,$fe,$02,$fe,$01,
  $fd,$00,$fe,$7f,$fe,$7e,$ff,$7d,$00,$7e,
  $01,$7d,$02,$7e,$02,$7f,$03,$00,$02,$01,
  $02,$02,$03,$fd,$0f,$95,$00,$6b,$00,$8b,
  $fe,$02,$fe,$01,$fd,$00,$fe,$7f,$fe,$7e,
  $ff,$7d,$00,$7e,$01,$7d,$02,$7e,$02,$7f,
  $03,$00,$02,$01,$02,$02,$04,$fd,$03,$88,
  $0c,$00,$00,$02,$ff,$02,$ff,$01,$fe,$01,
  $fd,$00,$fe,$7f,$fe,$7e,$ff,$7d,$00,$7e,
  $01,$7d,$02,$7e,$02,$7f,$03,$00,$02,$01,
  $02,$02,$03,$fd,$0a,$95,$fe,$00,$fe,$7f,
  $ff,$7d,$00,$6f,$fd,$8e,$07,$00,$03,$f2,
  $0f,$8e,$00,$70,$ff,$7d,$ff,$7f,$fe,$7f,
  $fd,$00,$fe,$01,$09,$91,$fe,$02,$fe,$01,
  $fd,$00,$fe,$7f,$fe,$7e,$ff,$7d,$00,$7e,
  $01,$7d,$02,$7e,$02,$7f,$03,$00,$02,$01,
  $02,$02,$04,$fd,$04,$95,$00,$6b,$00,$8a,
  $03,$03,$02,$01,$03,$00,$02,$7f,$01,$7d,
  $00,$76,$04,$80,$03,$95,$01,$7f,$01,$01,
  $ff,$01,$ff,$7f,$01,$f9,$00,$72,$04,$80,
  $05,$95,$01,$7f,$01,$01,$ff,$01,$ff,$7f,
  $01,$f9,$00,$6f,$ff,$7d,$fe,$7f,$fe,$00,
  $09,$87,$04,$95,$00,$6b,$0a,$8e,$f6,$76,
  $04,$84,$07,$78,$02,$80,$04,$95,$00,$6b,
  $04,$80,$04,$8e,$00,$72,$00,$8a,$03,$03,
  $02,$01,$03,$00,$02,$7f,$01,$7d,$00,$76,
  $00,$8a,$03,$03,$02,$01,$03,$00,$02,$7f,
  $01,$7d,$00,$76,$04,$80,$04,$8e,$00,$72,
  $00,$8a,$03,$03,$02,$01,$03,$00,$02,$7f,
  $01,$7d,$00,$76,$04,$80,$08,$8e,$fe,$7f,
  $fe,$7e,$ff,$7d,$00,$7e,$01,$7d,$02,$7e,
  $02,$7f,$03,$00,$02,$01,$02,$02,$01,$03,
  $00,$02,$ff,$03,$fe,$02,$fe,$01,$fd,$00,
  $0b,$f2,$04,$8e,$00,$6b,$00,$92,$02,$02,
  $02,$01,$03,$00,$02,$7f,$02,$7e,$01,$7d,
  $00,$7e,$ff,$7d,$fe,$7e,$fe,$7f,$fd,$00,
  $fe,$01,$fe,$02,$0f,$fd,$0f,$8e,$00,$6b,
  $00,$92,$fe,$02,$fe,$01,$fd,$00,$fe,$7f,
  $fe,$7e,$ff,$7d,$00,$7e,$01,$7d,$02,$7e,
  $02,$7f,$03,$00,$02,$01,$02,$02,$04,$fd,
  $04,$8e,$00,$72,$00,$88,$01,$03,$02,$02,
  $02,$01,$03,$00,$01,$f2,$0e,$8b,$ff,$02,
  $fd,$01,$fd,$00,$fd,$7f,$ff,$7e,$01,$7e,
  $02,$7f,$05,$7f,$02,$7f,$01,$7e,$00,$7f,
  $ff,$7e,$fd,$7f,$fd,$00,$fd,$01,$ff,$02,
  $0e,$fd,$05,$95,$00,$6f,$01,$7d,$02,$7f,
  $02,$00,$f8,$8e,$07,$00,$03,$f2,$04,$8e,
  $00,$76,$01,$7d,$02,$7f,$03,$00,$02,$01,
  $03,$03,$00,$8a,$00,$72,$04,$80,$02,$8e,
  $06,$72,$06,$8e,$fa,$72,$08,$80,$03,$8e,
  $04,$72,$04,$8e,$fc,$72,$04,$8e,$04,$72,
  $04,$8e,$fc,$72,$07,$80,$03,$8e,$0b,$72,
  $00,$8e,$f5,$72,$0e,$80,$02,$8e,$06,$72,
  $06,$8e,$fa,$72,$fe,$7c,$fe,$7e,$fe,$7f,
  $ff,$00,$0f,$87,$0e,$8e,$f5,$72,$00,$8e,
  $0b,$00,$f5,$f2,$0b,$00,$03,$80,$09,$99,
  $fe,$7f,$ff,$7f,$ff,$7e,$00,$7e,$01,$7e,
  $01,$7f,$01,$7e,$00,$7e,$fe,$7e,$01,$8e,
  $ff,$7e,$00,$7e,$01,$7e,$01,$7f,$01,$7e,
  $00,$7e,$ff,$7e,$fc,$7e,$04,$7e,$01,$7e,
  $00,$7e,$ff,$7e,$ff,$7f,$ff,$7e,$00,$7e,
  $01,$7e,$ff,$8e,$02,$7e,$00,$7e,$ff,$7e,
  $ff,$7f,$ff,$7e,$00,$7e,$01,$7e,$01,$7f,
  $02,$7f,$05,$87,$04,$95,$00,$77,$00,$fd,
  $00,$77,$04,$80,$05,$99,$02,$7f,$01,$7f,
  $01,$7e,$00,$7e,$ff,$7e,$ff,$7f,$ff,$7e,
  $00,$7e,$02,$7e,$ff,$8e,$01,$7e,$00,$7e,
  $ff,$7e,$ff,$7f,$ff,$7e,$00,$7e,$01,$7e,
  $04,$7e,$fc,$7e,$ff,$7e,$00,$7e,$01,$7e,
  $01,$7f,$01,$7e,$00,$7e,$ff,$7e,$01,$8e,
  $fe,$7e,$00,$7e,$01,$7e,$01,$7f,$01,$7e,
  $00,$7e,$ff,$7e,$ff,$7f,$fe,$7f,$09,$87,
  $03,$86,$00,$02,$01,$03,$02,$01,$02,$00,
  $02,$7f,$04,$7d,$02,$7f,$02,$00,$02,$01,
  $01,$02,$ee,$fe,$01,$02,$02,$01,$02,$00,
  $02,$7f,$04,$7d,$02,$7f,$02,$00,$02,$01,
  $01,$03,$00,$02,$03,$f4,$10,$80,$03,$80,
  $07,$15,$08,$6b,$fe,$85,$f5,$00,$10,$fb,
  $0d,$95,$f6,$00,$00,$6b,$0a,$00,$02,$02,
  $00,$08,$fe,$02,$f6,$00,$0e,$f4,$03,$80,
  $00,$15,$0a,$00,$02,$7e,$00,$7e,$00,$7d,
  $00,$7e,$fe,$7f,$f6,$00,$0a,$80,$02,$7e,
  $01,$7e,$00,$7d,$ff,$7d,$fe,$7f,$f6,$00,
  $10,$80,$03,$80,$00,$15,$0c,$00,$ff,$7e,
  $03,$ed,$03,$fd,$00,$03,$02,$00,$00,$12,
  $02,$03,$0a,$00,$00,$6b,$02,$00,$00,$7d,
  $fe,$83,$f4,$00,$11,$80,$0f,$80,$f4,$00,
  $00,$15,$0c,$00,$ff,$f6,$f5,$00,$0f,$f5,
  $04,$95,$07,$76,$00,$0a,$07,$80,$f9,$76,
  $00,$75,$f8,$80,$07,$0c,$09,$f4,$f9,$0c,
  $09,$f4,$03,$92,$02,$03,$07,$00,$03,$7d,
  $00,$7b,$fc,$7e,$04,$7d,$00,$7a,$fd,$7e,
  $f9,$00,$fe,$02,$06,$89,$02,$00,$06,$f5,
  $03,$95,$00,$6b,$0c,$15,$00,$6b,$02,$80,
  $03,$95,$00,$6b,$0c,$15,$00,$6b,$f8,$96,
  $03,$00,$07,$ea,$03,$80,$00,$15,$0c,$80,
  $f7,$76,$fd,$00,$03,$80,$0a,$75,$03,$80,
  $03,$80,$07,$13,$02,$02,$03,$00,$00,$6b,
  $02,$80,$03,$80,$00,$15,$09,$6b,$09,$15,
  $00,$6b,$03,$80,$03,$80,$00,$15,$00,$f6,
  $0d,$00,$00,$8a,$00,$6b,$03,$80,$07,$80,
  $fd,$00,$ff,$03,$00,$04,$00,$07,$00,$04,
  $01,$02,$03,$01,$06,$00,$03,$7f,$01,$7e,
  $01,$7c,$00,$79,$ff,$7c,$ff,$7d,$fd,$00,
  $fa,$00,$0e,$80,$03,$80,$00,$15,$0c,$00,
  $00,$6b,$02,$80,$03,$80,$00,$15,$0a,$00,
  $02,$7f,$01,$7d,$00,$7b,$ff,$7e,$fe,$7f,
  $f6,$00,$10,$f7,$11,$8f,$ff,$03,$ff,$02,
  $fe,$01,$fa,$00,$fd,$7f,$ff,$7e,$00,$7c,
  $00,$79,$00,$7b,$01,$7e,$03,$00,$06,$00,
  $02,$00,$01,$03,$01,$02,$03,$fb,$03,$95,
  $0c,$00,$fa,$80,$00,$6b,$09,$80,$03,$95,
  $00,$77,$06,$7a,$06,$06,$00,$09,$fa,$f1,
  $fa,$7a,$0e,$80,$03,$87,$00,$0b,$02,$02,
  $03,$00,$02,$7e,$01,$02,$04,$00,$02,$7e,
  $00,$75,$fe,$7e,$fc,$00,$ff,$01,$fe,$7f,
  $fd,$00,$fe,$02,$07,$8e,$00,$6b,$09,$80,
  $03,$80,$0e,$15,$f2,$80,$0e,$6b,$03,$80,
  $03,$95,$00,$6b,$0e,$00,$00,$7d,$fe,$98,
  $00,$6b,$05,$80,$03,$95,$00,$75,$02,$7d,
  $0a,$00,$00,$8e,$00,$6b,$02,$80,$03,$95,
  $00,$6b,$10,$00,$00,$15,$f8,$80,$00,$6b,
  $0a,$80,$03,$95,$00,$6b,$10,$00,$00,$15,
  $f8,$80,$00,$6b,$0a,$00,$00,$7d,$02,$83,
  $10,$80,$03,$95,$00,$6b,$09,$00,$03,$02,
  $00,$08,$fd,$02,$f7,$00,$0e,$89,$00,$6b,
  $03,$80,$03,$95,$00,$6b,$09,$00,$03,$02,
  $00,$08,$fd,$02,$f7,$00,$0e,$f4,$03,$92,
  $02,$03,$07,$00,$03,$7d,$00,$70,$fd,$7e,
  $f9,$00,$fe,$02,$03,$89,$09,$00,$02,$f5,
  $03,$80,$00,$15,$00,$f5,$07,$00,$00,$08,
  $02,$03,$06,$00,$02,$7d,$00,$70,$fe,$7e,
  $fa,$00,$fe,$02,$00,$08,$0c,$f6,$0f,$80,
  $00,$15,$f6,$00,$fe,$7d,$00,$79,$02,$7e,
  $0a,$00,$f4,$f7,$07,$09,$07,$f7,$03,$8c,
  $01,$02,$01,$01,$05,$00,$02,$7f,$01,$7e,
  $00,$74,$00,$86,$ff,$01,$fe,$01,$fb,$00,
  $ff,$7f,$ff,$7f,$00,$7c,$01,$7e,$01,$00,
  $05,$00,$02,$00,$01,$02,$03,$fe,$04,$8e,
  $02,$01,$04,$00,$02,$7f,$01,$7e,$00,$77,
  $ff,$7e,$fe,$7f,$fc,$00,$fe,$01,$ff,$02,
  $00,$09,$01,$02,$02,$02,$03,$01,$02,$01,
  $01,$01,$01,$02,$02,$eb,$03,$80,$00,$15,
  $03,$00,$02,$7e,$00,$7b,$fe,$7e,$fd,$00,
  $03,$80,$04,$00,$03,$7e,$00,$78,$fd,$7e,
  $f9,$00,$0c,$80,$03,$8c,$02,$02,$02,$01,
  $03,$00,$02,$7f,$01,$7d,$fe,$7e,$f9,$7d,
  $ff,$7e,$00,$7d,$03,$7f,$02,$00,$03,$01,
  $02,$01,$02,$fe,$0d,$8c,$ff,$02,$fe,$01,
  $fc,$00,$fe,$7f,$ff,$7e,$00,$77,$01,$7e,
  $02,$7f,$04,$00,$02,$01,$01,$02,$00,$0f,
  $ff,$02,$fe,$01,$f9,$00,$0c,$eb,$03,$88,
  $0a,$00,$00,$02,$00,$03,$fe,$02,$fa,$00,
  $ff,$7e,$ff,$7d,$00,$7b,$01,$7c,$01,$7f,
  $06,$00,$02,$02,$03,$fe,$03,$8f,$06,$77,
  $06,$09,$fa,$80,$00,$71,$ff,$87,$fb,$79,
  $07,$87,$05,$79,$02,$80,$03,$8d,$02,$02,
  $06,$00,$02,$7e,$00,$7d,$fc,$7d,$04,$7e,
  $00,$7d,$fe,$7e,$fa,$00,$fe,$02,$04,$85,
  $02,$00,$06,$f9,$03,$8f,$00,$73,$01,$7e,
  $07,$00,$02,$02,$00,$0d,$00,$f3,$01,$7e,
  $03,$80,$03,$8f,$00,$73,$01,$7e,$07,$00,
  $02,$02,$00,$0d,$00,$f3,$01,$7e,$f8,$90,
  $03,$00,$08,$f0,$03,$80,$00,$15,$00,$f3,
  $02,$00,$06,$07,$fa,$f9,$07,$78,$03,$80,
  $03,$80,$04,$0c,$02,$03,$04,$00,$00,$71,
  $02,$80,$03,$80,$00,$0f,$06,$77,$06,$09,
  $00,$71,$02,$80,$03,$80,$00,$0f,$0a,$f1,
  $00,$0f,$f6,$f8,$0a,$00,$02,$f9,$05,$80,
  $ff,$01,$ff,$04,$00,$05,$01,$03,$01,$02,
  $06,$00,$02,$7e,$00,$7d,$00,$7b,$00,$7c,
  $fe,$7f,$fa,$00,$0b,$80,$03,$80,$00,$0f,
  $00,$fb,$01,$03,$01,$02,$05,$00,$02,$7e,
  $01,$7d,$00,$76,$03,$80,$10,$80,$10,$80,
  $10,$80,$10,$80,$10,$80,$10,$80,$10,$80,
  $10,$80,$10,$80,$10,$80,$10,$80,$10,$80,
  $10,$80,$10,$80,$10,$80,$10,$80,$10,$80,
  $10,$80,$10,$80,$10,$80,$10,$80,$10,$80,
  $10,$80,$10,$80,$10,$80,$10,$80,$10,$80,
  $10,$80,$10,$80,$10,$80,$10,$80,$10,$80,
  $10,$80,$10,$80,$10,$80,$10,$80,$10,$80,
  $10,$80,$10,$80,$10,$80,$10,$80,$10,$80,
  $10,$80,$10,$80,$10,$80,$10,$80,$10,$80,
  $10,$80,$0a,$8f,$02,$7f,$01,$7e,$00,$76,
  $ff,$7f,$fe,$7f,$fb,$00,$ff,$01,$ff,$01,
  $00,$0a,$01,$02,$01,$01,$05,$00,$f9,$80,
  $00,$6b,$0c,$86,$0d,$8a,$ff,$03,$fe,$02,
  $fb,$00,$ff,$7e,$ff,$7d,$00,$7b,$01,$7c,
  $01,$7f,$05,$00,$02,$01,$01,$03,$03,$fc,
  $03,$80,$00,$0f,$00,$fb,$01,$03,$01,$02,
  $04,$00,$01,$7e,$01,$7d,$00,$76,$00,$8a,
  $01,$03,$02,$02,$03,$00,$02,$7e,$01,$7d,
  $00,$76,$03,$80,$03,$8f,$00,$74,$01,$7e,
  $02,$7f,$04,$00,$02,$01,$01,$01,$00,$8d,
  $00,$6e,$ff,$7e,$fe,$7f,$fb,$00,$fe,$01,
  $0c,$85,$03,$8d,$01,$02,$03,$00,$02,$7e,
  $01,$02,$03,$00,$02,$7e,$00,$74,$fe,$7f,
  $fd,$00,$ff,$01,$fe,$7f,$fd,$00,$ff,$01,
  $00,$0c,$06,$82,$00,$6b,$08,$86,$03,$80,
  $0a,$0f,$f6,$80,$0a,$71,$03,$80,$03,$8f,
  $00,$73,$01,$7e,$07,$00,$02,$02,$00,$0d,
  $00,$f3,$01,$7e,$00,$7e,$03,$82,$03,$8f,
  $00,$79,$02,$7e,$08,$00,$00,$89,$00,$71,
  $02,$80,$03,$8f,$00,$73,$01,$7e,$03,$00,
  $02,$02,$00,$0d,$00,$f3,$01,$7e,$03,$00,
  $02,$02,$00,$0d,$00,$f3,$01,$7e,$03,$80,
  $03,$8f,$00,$73,$01,$7e,$03,$00,$02,$02,
  $00,$0d,$00,$f3,$01,$7e,$03,$00,$02,$02,
  $00,$0d,$00,$f3,$01,$7e,$00,$7e,$03,$82,
  $03,$8d,$00,$02,$02,$00,$00,$71,$08,$00,
  $02,$02,$00,$06,$fe,$02,$f8,$00,$0c,$f6,
  $03,$8f,$00,$71,$07,$00,$02,$02,$00,$06,
  $fe,$02,$f9,$00,$0c,$85,$00,$71,$02,$80,
  $03,$8f,$00,$71,$07,$00,$03,$02,$00,$06,
  $fd,$02,$f9,$00,$0c,$f6,$03,$8d,$02,$02,
  $06,$00,$02,$7e,$00,$75,$fe,$7e,$fa,$00,
  $fe,$02,$04,$85,$06,$00,$02,$f9,$03,$80,
  $00,$0f,$00,$f8,$04,$00,$00,$06,$02,$02,
  $04,$00,$02,$7e,$00,$75,$fe,$7e,$fc,$00,
  $fe,$02,$00,$05,$0a,$f9,$0d,$80,$00,$0f,
  $f7,$00,$ff,$7e,$00,$7b,$01,$7e,$09,$00,
  $f6,$fa,$04,$06,$08,$fa );

{ UNIT IMPLEMENTATION }
{ CONSTRUCT }
constructor gsv_text.Construct;
var
 t : int;

begin
 inherited Construct;

 m_x          :=0.0;
 m_y          :=0.0;
 m_start_x    :=0.0;
 m_width      :=10.0;
 m_height     :=0.0;
 m_space      :=0.0;
 m_line_space :=0.0;
 m_text       :=@m_chr[0 ];
 m_text_buf   :=NIL;
 m_buf_size   :=0;
 m_cur_chr    :=@m_chr[0 ];
 m_font       :=@gsv_default_font[0 ];
 m_loaded_font:=NIL;
 m_loadfont_sz:=0;
 m_status     :=initial;
 m_big_endian :=false;
 m_flip       :=false;

 m_chr[0 ]:=0;
 m_chr[1 ]:=0;

 t:=1;

 if byte(pointer(@t )^ ) = 0 then
  m_big_endian:=true;

end;

{ DESTRUCT }
destructor gsv_text.Destruct;
begin
 inherited Destruct;

 if m_loaded_font <> NIL then
  agg_freemem(m_loaded_font ,m_loadfont_sz );

 if m_text_buf <> NIL then
  agg_freemem(m_text_buf ,m_buf_size );

end;

{ FONT_ }
procedure gsv_text.font_;
begin
 m_font:=font;

 if m_font = NIL then
  m_font:=m_loaded_font;

end;

{ FLIP_ }
procedure gsv_text.flip_;
begin
 m_flip:=flip_y;

end;

{ LOAD_FONT_ }
procedure gsv_text.load_font_;
var
 fd  : file;
 err : integer;

begin
 if m_loaded_font <> NIL then
  agg_freemem(m_loaded_font ,m_loadfont_sz );

{$I- }
 err:=ioresult;

 assignfile(fd ,_file_ );
 reset     (fd ,1 );

 err:=ioresult;

 if err = 0 then
  begin
   m_loadfont_sz:=filesize(fd );

   if m_loadfont_sz > 0 then
    begin
     agg_getmem(m_loaded_font ,m_loadfont_sz );
     blockread (fd ,m_loaded_font^ ,m_loadfont_sz );

     m_font:=m_loaded_font;

    end;

   close(fd );

  end;

end;

{ SIZE_ }
procedure gsv_text.size_;
begin
 m_height:=height;
 m_width :=width;

end;

{ SPACE_ }
procedure gsv_text.space_;
begin
 m_space:=space;

end;

{ LINE_SPACE_ }
procedure gsv_text.line_space_;
begin
 m_line_space:=line_space;

end;

{ START_POINT_ }
procedure gsv_text.start_point_;
begin
 m_x:=x;
 m_y:=y;

 m_start_x:=x;

end;

{ TEXT_ }
procedure gsv_text.text_;
var
 new_size : unsigned;

begin
 if text = NIL then
  begin
   m_chr[0 ]:=0;
   m_text   :=@m_chr[0 ];

   exit;

  end;

 new_size:=StrLen(text ) + 1;

 if new_size > m_buf_size then
  begin
   if m_text_buf <> NIL then
    agg_freemem(m_text_buf ,m_buf_size );

   agg_getmem(m_text_buf ,new_size );

   m_buf_size:=new_size;

  end;

 move(text^ ,m_text_buf^ ,new_size );

 m_text:=m_text_buf;

end;

{ REWIND }
procedure gsv_text.rewind;
var
 base_height : double;

begin
 m_status:=initial;

 if m_font = NIL then
  exit;

 m_indices:=m_font;

 base_height:=_value(pointer(ptrcomp(m_indices ) + 4 * sizeof(int8u ) ) );

 m_indices:=pointer(ptrcomp(m_indices ) + _value(m_indices ) );
 m_glyphs :=pointer(ptrcomp(m_indices ) + 257 * 2 * sizeof(int8u ) );

 m_h:= m_height / base_height;

 if m_width = 0 then
  m_w:=m_h
 else
  m_w:=m_width / base_height;

 if m_flip then
  m_h:=-m_h;

 m_cur_chr:=m_text;

end;

{ VERTEX }
function gsv_text.vertex;
var
 idx : unsigned;

 yc ,yf : int8;
 dx ,dy : int;

 quit : boolean;

label
 _nxch ,_strt ; 

begin
 quit:=false;

 while not quit do
  case m_status of
   initial :
    if m_font = NIL then
     quit:=true

    else
     begin
      m_status:=next_char;

      goto _nxch;

     end;

   next_char :
   _nxch:
    if m_cur_chr^ = 0 then
     quit:=true
     
    else
     begin
      idx:=m_cur_chr^ and $FF;

      inc(ptrcomp(m_cur_chr ) ,sizeof(int8u ) );

      if idx = 13 then
       begin
        m_x:=m_start_x;

        if m_flip then
         m_y:=m_y - (-m_height - m_line_space )
        else
         m_y:=m_y - (m_height + m_line_space );

       end
      else
       begin
        idx:=idx shl 1;

        m_bglyph:=pointer(ptrcomp(m_glyphs ) + _value(pointer(ptrcomp(m_indices ) + idx ) ) );
        m_eglyph:=pointer(ptrcomp(m_glyphs ) + _value(pointer(ptrcomp(m_indices ) + idx + 2 ) ) );
        m_status:=start_glyph;

        goto _strt;

       end;

     end;

   start_glyph :
   _strt:
    begin
     x^:=m_x;
     y^:=m_y;

     m_status:=glyph;

     result:=path_cmd_move_to;

     exit;

    end;

   glyph :
    if ptrcomp(m_bglyph ) >= ptrcomp(m_eglyph ) then
     begin
      m_status:=next_char;

      m_x:=m_x + m_space;

     end
    else
     begin
      dx:=int(m_bglyph^ );

      inc(ptrcomp(m_bglyph ) ,sizeof(int8u ) );

      yc:=m_bglyph^;

      inc(ptrcomp(m_bglyph ) ,sizeof(int8u ) );

      yf:=yc and $80;
      yc:=yc shl 1;
      yc:=shr_int8(yc ,1 );

      dy:=yc;

      m_x:=m_x + (dx * m_w );
      m_y:=m_y + (dy * m_h );

      x^:=m_x;
      y^:=m_y;

      if yf <> 0 then
       result:=path_cmd_move_to
      else
       result:=path_cmd_line_to;

      exit;

     end;

  end;

 result:=path_cmd_stop;

end;

{ _VALUE }
function gsv_text._value;
var
 v : int16u;

begin
 if m_big_endian then
  begin
   int16u_(v ).Low :=int8u_ptr(ptrcomp(p ) + 1 )^;
   int16u_(v ).High:=p^;

  end
 else
  begin
   int16u_(v ).Low :=p^;
   int16u_(v ).High:=int8u_ptr(ptrcomp(p ) + 1 )^;

  end;

 result:=v;

end;

{ CONSTRUCT }
constructor gsv_text_outline.Construct;
begin
 m_polyline.Construct(text );
 m_trans.Construct   (@m_polyline ,trans );

end;

{ DESTRUCT }
destructor gsv_text_outline.Destruct;
begin
 m_polyline.Destruct;

end;

{ WIDTH_ }
procedure gsv_text_outline.width_;
begin
 m_polyline.width_(w );

end;

{ TRANSFORMER_ }
procedure gsv_text_outline.transformer_;
begin
 m_trans.transformer_(trans );

end;

{ REWIND }
procedure gsv_text_outline.rewind;
begin
 m_trans.rewind(path_id );

 m_polyline.line_join_(round_join );
 m_polyline.line_cap_ (round_cap );

end;

{ VERTEX }
function gsv_text_outline.vertex;
begin
 result:=m_trans.vertex(x ,y );

end;

END.

