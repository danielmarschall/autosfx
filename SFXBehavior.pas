unit SFXBehavior;

interface

uses
  SysUtils;

type
  TConflictBehavior = (cbAvoid, cbOverwrite, cbNewer, cbAsk);

  TCommentPresentation = (cpNone, cpBeforeExtracting, cpAfterExtracting);

  TExtractionTarget = (etExtractHere, etDesktop, etAsk);

  TZIPBehavior = record
    ConflictBehavior: TConflictBehavior;
    CommentPresentation: TCommentPresentation;
    ExtractionTarget: TExtractionTarget;
  end;

function ReadBehavior(c: string): TZIPBehavior;
function StripBehavior(c: string): string;
function BehaviorStrings(bh: TZipBehavior): string;
function RelocateBehaviorStringsToEnd(c: string): string;

implementation

const
  C_SIGNATURE   = 'ViaThinkSoft AutoSFX Archive Configuration';

  C_ASFX_CB_OVR = 'AutoSFX Conflict Behavior: Overwrite all';
  C_ASFX_CB_NEW = 'AutoSFX Conflict Behavior: Overwrite older';
  C_ASFX_CB_ASK = 'AutoSFX Conflict Behavior: Ask';
  C_ASFX_CB_AVO = 'AutoSFX Conflict Behavior: Avoid';

  C_ASFX_CP_BEF = 'AutoSFX Comment Presentation: Before extracting';
  C_ASFX_CP_AFT = 'AutoSFX Comment Presentation: After extracting';
  C_ASFX_CP_NON = 'AutoSFX Comment Presentation: None';

  C_ASFX_ET_HER = 'AutoSFX Extraction Target: Extract here';
  C_ASFX_ET_DES = 'AutoSFX Extraction Target: Extract to Desktop';
  C_ASFX_ET_ASK = 'AutoSFX Extraction Target: Choose directory';

  EINRUECK      = '> '; // Optional

const
  CB_DEFAULT = cbAvoid;
  CP_DEFAULT = cpNone;
  ET_DEFAULT = etExtractHere;

function ReadBehavior(c: string): TZIPBehavior;

  function Vorkommen(s: string): boolean;
  begin
    s := AnsiLowerCase(s);
    result := AnsiPos(s, c) > 0;
  end;

begin
  result.ConflictBehavior := CB_DEFAULT;
  result.CommentPresentation := CP_DEFAULT;
  result.ExtractionTarget := ET_DEFAULT;

  c := AnsiLowerCase(c);

  if Vorkommen(C_ASFX_CB_OVR) then
  begin
    result.ConflictBehavior := cbOverwrite;
  end
  else if Vorkommen(C_ASFX_CB_NEW) then
  begin
    result.ConflictBehavior := cbNewer;
  end
  else if Vorkommen(C_ASFX_CB_ASK) then
  begin
    result.ConflictBehavior := cbAsk;
  end
  else if Vorkommen(C_ASFX_CB_AVO) then
  begin
    result.ConflictBehavior := cbAvoid;
  end;

  if Vorkommen(C_ASFX_CP_BEF) then
  begin
    result.CommentPresentation := cpBeforeExtracting;
  end
  else if Vorkommen(C_ASFX_CP_AFT) then
  begin
    result.CommentPresentation := cpAfterExtracting;
  end
  else if Vorkommen(C_ASFX_CP_NON) then
  begin
    result.CommentPresentation := cpNone;
  end;

  if Vorkommen(C_ASFX_ET_HER) then
  begin
    result.ExtractionTarget := etExtractHere;
  end
  else if Vorkommen(C_ASFX_ET_DES) then
  begin
    result.ExtractionTarget := etDesktop;
  end
  else if Vorkommen(C_ASFX_ET_ASK) then
  begin
    result.ExtractionTarget := etAsk;
  end;
end;

function StripBehavior(c: string): string;

  procedure StripIt(s: string);
  begin
    c := StringReplace(c, EINRUECK + s+#13#10, '', [rfReplaceAll, rfIgnoreCase]);
    c := StringReplace(c, EINRUECK + s+#13,    '', [rfReplaceAll, rfIgnoreCase]);
    c := StringReplace(c, EINRUECK + s+#10,    '', [rfReplaceAll, rfIgnoreCase]);
    c := StringReplace(c, EINRUECK + s,        '', [rfReplaceAll, rfIgnoreCase]);

    c := StringReplace(c, s+#13#10, '', [rfReplaceAll, rfIgnoreCase]);
    c := StringReplace(c, s+#13,    '', [rfReplaceAll, rfIgnoreCase]);
    c := StringReplace(c, s+#10,    '', [rfReplaceAll, rfIgnoreCase]);
    c := StringReplace(c, s,        '', [rfReplaceAll, rfIgnoreCase]);
  end;

begin
  StripIt(C_SIGNATURE);

  StripIt(C_ASFX_CB_AVO);
  StripIt(C_ASFX_CB_OVR);
  StripIt(C_ASFX_CB_NEW);
  StripIt(C_ASFX_CB_ASK);

  StripIt(C_ASFX_CP_NON);
  StripIt(C_ASFX_CP_BEF);
  StripIt(C_ASFX_CP_AFT);

  StripIt(C_ASFX_ET_HER);
  StripIt(C_ASFX_ET_DES);
  StripIt(C_ASFX_ET_ASK);

  result := c;
end;

function BehaviorStrings(bh: TZipBehavior): string;
begin
  result := C_SIGNATURE + #13#10 + EINRUECK;

  case bh.ConflictBehavior of
    cbAvoid:     result := result + C_ASFX_CB_AVO;
    cbOverwrite: result := result + C_ASFX_CB_OVR;
    cbNewer:     result := result + C_ASFX_CB_NEW;
    cbAsk:       result := result + C_ASFX_CB_ASK;
  end;

  result := result + #13#10 + EINRUECK;

  case bh.CommentPresentation of
    cpNone:             result := result + C_ASFX_CP_NON;
    cpBeforeExtracting: result := result + C_ASFX_CP_BEF;
    cpAfterExtracting:  result := result + C_ASFX_CP_AFT;
  end;

  result := result + #13#10 + EINRUECK;

  case bh.ExtractionTarget of
    etExtractHere: result := result + C_ASFX_ET_HER;
    etDesktop:     result := result + C_ASFX_ET_DES;
    etAsk:         result := result + C_ASFX_ET_ASK;
  end;

  result := result + #13#10;
end;

function RelocateBehaviorStringsToEnd(c: string): string;
var
  bh: TZIPBehavior;
begin
  bh := ReadBehavior(c);
  c := StripBehavior(c);
  c := TrimRight(c);
  c := c + #13#10 + #13#10;
  c := c + BehaviorStrings(bh);
  result := c;
end;

end.
