unit UnicodeProcessFrm;

(* This application produces a unicodeData.pas file by reading the unicodeData.txt file that is produced by
   The Unicode Consortium.  See http://www.unicode.org.
   Specifically, the file we are reading is from https://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt

   Then, once the unicodeData.pas file is produced, the CompareTextUnicode function below will use the constants defined
   in unicodeData.txt to compare two standard delphi strings with case insensitivity considering all unicode defined
   upperCase to lowerCase pairings.  Since the delphi standard System.SysUtils.CompareText function doesn't fully address
   the case of any characters beyond the ascii characters, this function is a more true implementation for comparing two
   unicode strings.   My hope is that Embarcadero will adopt this code, improve on it by writing a direct assembly version
   of it for improved performance, and include it in the standard delphi libraries as a replacement to the existing compareText function.
*)

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, UnicodeData;

type
  TForm34 = class(TForm)
    Memo1: TMemo;
    btnGO: TButton;
    btnTest: TButton;
    btnPerformanceTest: TButton;
    btnTestCompareText: TButton;
    procedure btnGOClick(Sender: TObject);
    procedure btnTestClick(Sender: TObject);
    procedure btnPerformanceTestClick(Sender: TObject);
    procedure btnTestCompareTextClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  TPairing = record
    Char1: word;
    Char2: word;
    description: string;
  end;


var
  Form34: TForm34;

implementation

{$R *.dfm}

procedure TForm34.btnGOClick(Sender: TObject);
var
  lFile: TStringList;
  lOutFile: TStringList;
  lRow: TStringList;
  i,j,k,l: Integer;
  lCase: array[0..2] of string;
  lCaseCount: integer;
  lMappings: array[0..65535] of TPairing;
  lCode: Cardinal;       // right now we are only handling 0 to 65535, but we also need to at least parse out all possible codes.
  lStr: string;

  lPageCounts1: array[0..255] of byte;     // each item holds the count of Char1 pairings
  lPageCounts2: array[0..255] of byte;     // each item holds the count of Char2 pairings
  lPageCount: integer;

  // shortcut for publishing to the memo
  procedure m(aStr: string);
  begin
    memo1.Lines.Add(aStr);
  end;

  // shortcut for Write to File
  procedure wf(aStr: string);
  begin
    lOutFile.Add(aStr);
  end;

  procedure ProduceCompareTextUnicodeInterface;
  begin
    wf('');
    wf('function CompareTextUnicode(const S1, S2: string): Integer;');
    wf('');
  end;

  procedure ProduceCompareTextUnicodeImplementation;
  begin
    wf('');
    wf('{This function uses the page index and the two pairing tables above to perform');
    wf(' a case insensitive comparison between two unicode strings because the standard System.SysUtils.CompareText');
    wf(' function only considers the basic ascii characters and not all of the unicode characters that it should.}');
    wf('');
    wf('function CompareTextUnicode(const S1, S2: string): Integer;');
    wf('var');
    wf('  I, Last: cardinal;');
    wf('  L1, L2: Integer;');
    wf('  Ch1, Ch2, lPairedCh: word;');
    wf('  lIndex: byte;');
    wf('begin');
    wf('  L1 := Length(S1);');
    wf('  L2 := Length(S2);');
    wf('  result := L1 - L2;');
    wf('  if (L1 > 0) and (L2 > 0) then');
    wf('  begin');
    wf('    if result < 0 then Last := L1 shl 1');
    wf('    else Last := L2 shl 1;');
    wf('');
    wf('    I := 0;');
    wf('    while I < Last do');
    wf('    begin');
    wf('      Ch1 := PWord(PByte(S1) + I)^;');
    wf('      Ch2 := PWord(PByte(S2) + I)^;');
    wf('');
    wf('      if Ch1 <> Ch2 then');
    wf('      begin');
    wf('        // Lookup the corresponding first possible pairing and compare to the second character');
    wf('        lIndex := cUnicodeCharacterPairsIndex1[Ch1 shr 8];      // Lookup the index value. If it is zero, then there''s no associated table to bother looking into.');
    wf('        if lIndex <> 0 then');
    wf('        begin');
    wf('          lPairedCh := cPairingTable1[lIndex-1,Ch1 and $FF];');
    wf('          if (lPairedCh <> 0) then');
    wf('          begin');
    wf('            if (Ch2 <> lPairedCh) then');
    wf('            begin');
    wf('              // Ch2 did not match the found paired Character from Ch1, so try to look into the secondary pairing table');
    wf('              lIndex := cUnicodeCharacterPairsIndex2[Ch1 shr 8];      // Lookup the index value. If it is zero, then there''s no associated table to bother looking into.');
    wf('              if lIndex <> 0 then');
    wf('              begin');
    wf('                lPairedCh := cPairingTable2[lIndex-1, Ch1 and $FF];');
    wf('                if lPairedCh <> 0 then');
    wf('                begin');
    wf('                  if (Ch2 <> lPairedCh) then');
    wf('                  begin');
    wf('                    // at this point we checked both pairingTable1 and pairingTable2 but didn''t get a match.  consider Ch1 and Ch2 different');
    wf('                    Exit(Ch1 - Ch2);');
    wf('                  end;');
    wf('                end');
    wf('                else');
    wf('                begin');
    wf('                  // no pairing found for the lookup character code so they must be different');
    wf('                  Exit(Ch1 - Ch2);');
    wf('                end;');
    wf('              end');
    wf('              else');
    wf('              begin');
    wf('                // no page index found for the lookup character code so characters must be different.');
    wf('                Exit(Ch1 - Ch2);');
    wf('              end;');
    wf('            end;');
    wf('          end');
    wf('          else');
    wf('          begin');
    wf('            // no pairing found for the lookup character code so they must be different');
    wf('            Exit(Ch1 - Ch2);');
    wf('          end;');
    wf('        end      ');
    wf('        else');
    wf('        begin');
    wf('          // no page index found for the lookup character code so characters must be different.');
    wf('          Exit(Ch1 - Ch2);');
    wf('        end;');
    wf('      end;');
    wf('');
    wf('      inc(I, 2);');
    wf('    end;');
    wf('  end;');
    wf('end;');
    wf('');

  end;

  procedure ProduceLicenseText;
  begin
    wf('{********************************************************************************}');
    wf('{                                                                                }');
    wf('{ MIT License                                                                    }');
    wf('{                                                                                }');
    wf('{ Copyright (c) 2022 Sean Solberg                                                }');
    wf('{                                                                                }');
    wf('{ Permission is hereby granted, free of charge, to any person obtaining a copy   }');
    wf('{ of this software and associated documentation files (the "Software"), to deal  }');
    wf('{ in the Software without restriction, including without limitation the rights   }');
    wf('{ to use, copy, modify, merge, publish, distribute, sublicense, and/or sell      }');
    wf('{ copies of the Software, and to permit persons to whom the Software is          }');
    wf('{ furnished to do so, subject to the following conditions:                       }');
    wf('{                                                                                }');
    wf('{ The above copyright notice and this permission notice shall be included in all }');
    wf('{ copies or substantial portions of the Software.                                }');
    wf('{                                                                                }');
    wf('{ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR     }');
    wf('{ IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,       }');
    wf('{ FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE    }');
    wf('{ AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         }');
    wf('{ LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,  }');
    wf('{ OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE  }');
    wf('{ SOFTWARE.                                                                      }');
    wf('{                                                                                }');
    wf('{********************************************************************************}');
  end;


  function AlreadyExists(aStr: string): boolean;
  begin
    result := false;
    if lCasecount >= 1 then
    begin
      if aStr = lCase[0] then
      begin
        result := true;
        exit;
      end;
    end;
    if lCasecount >= 2 then
    begin
      if aStr = lCase[1] then
      begin
        result := true;
        exit;
      end;
    end;
    if lCasecount = 3 then
    begin
      if aStr = lCase[2] then
      begin
        result := true;
        exit;
      end;
    end;
  end;

  Procedure PublishPairingIndex(aName: string; aNumber: integer);
  var
    i,j: integer;
    lStr: string;
  begin
    wf('');
    wf('const');
    wf('  '+aName+': array[0..255] of byte = (');
    lPageCount := 0;
    j := 0;
    lStr := '    ';
    for i := 0 to 255 do
    begin
      if ((aNumber = 0) and (lPageCounts1[i] > 0)) or
         ((aNumber = 1) and (lPageCounts2[i] > 0))  then
      begin
        inc(lPageCount);
        lStr := lStr + InttoStr(lPageCount);
      end
      else
      begin
        lStr := lStr + '0';
      end;

      if i<255 then
        lStr := lStr + ', ';

      inc(j);

      if j = 16 then
      begin
        wf(lStr);
        j := 0;
        lStr := '    ';
      end;
    end;
    wf('  );');
  end;


  procedure PublishPairingTable(aNumber: integer; aCount: integer);
  var
    i,j,k,l: integer;
    lStr: string;
  begin
    wf('');
    wf('const');
    if aNumber = 0 then
      wf('  cPairingTable1: array[0..'+IntToStr(aCount-1)+',0..255] of word = (')
    else
      wf('  cPairingTable2: array[0..'+IntToStr(aCount-1)+',0..255] of word = (');

    l := 0;
    for i := 0 to 255 do
    begin
      if aNumber = 0 then
      begin
        if lPageCounts1[i] = 0 then continue;  // only include data in the table if the page has something
      end
      else
      begin
        if lPageCounts2[i] = 0 then continue;  // only include data in the table if the page has something
      end;

      lStr := '    (';
      k := 0;
      for j := 0 to 255 do
      begin
        if aNumber = 0 then
          lStr := lStr + '$'+intToHex(lMappings[i shl 8 + j].Char1,4)
        else
          lStr := lStr + '$'+intToHex(lMappings[i shl 8 + j].Char2,4);
        if j < 255 then
          lStr := lStr + ',';
        inc(k);
        if k = 16 then
        begin
          wf(lStr);
          lStr := '     ';
          k := 0;
        end;
      end;
      inc(l);

      if l = aCount then
        wf('    )')
      else
        wf('    ),');
    end;
    wf('  );');
  end;

begin
  // Initialize mappings
  for I := low(lMappings) to High(lMappings) do
  begin
    lMappings[i].Char1 := 0;
    lMappings[i].Char2 := 0;
  end;

  //Initialize the two pages tables
  for I := low(lPageCounts1) to High(lPageCounts1) do
  begin
    lPageCounts1[i]:=0;
    lPageCounts2[i]:=0;
  end;


  lFile:=TStringList.Create;
  lOutFile:=TStringList.Create;
  lRow:=TStringList.Create;
  try
    // Load and process the unicodeData.txt file.
    lFile.LoadFromFile('..\..\unicodedata.txt');       // assuming a default delphi project directory structure

    for i := 0 to lFile.Count-1 do
    begin
      lRow.Clear;

      lRow.Delimiter := ';';
      lRow.StrictDelimiter := true;
      lRow.QuoteChar := #0;
      lRow.DelimitedText := lFile.Strings[i];

      if lRow.count <> 15 then
      begin
        m('Error parsing unicodedata.txt.  Record '+intToStr(i)+' does not have exactly 15 fields: '+lFile.Strings[i]);
      end
      else
      begin
        lCode := StrToInt('$'+lRow[0]);

        // Right now, this code only deals with the Basic Multilingual Plane. Any code point outside of that is not going to be handled.
        if lCode < 65535 then
        begin
          if (lRow[12] <> '') or (lRow[13] <> '') or (lRow[14] <> '') then
          begin
            // we may have one, two or three values given to us here.  Also, one of them may match the main code we are processing.  So, boil it down to the two possible pairings
            lCaseCount := 0;
            if (lRow[12] <> '') and (lRow[0] <> lRow[12]) then
            begin
              lCase[lCaseCount] := lRow[12];
              inc(lCaseCount);
            end;

            if (lRow[13] <> '') and (lRow[0] <> lRow[13]) then
            begin
              if not AlreadyExists(lRow[13]) then
              begin
                lCase[lCaseCount] := lRow[13];
                inc(lCaseCount);
              end;
            end;

            if (lRow[14] <> '') and (lRow[0] <> lRow[14]) then
            begin
              if not AlreadyExists(lRow[14]) then
              begin
                lCase[lCaseCount] := lRow[14];
                inc(lCaseCount);
              end;
            end;

            // Now check our results
            if (length(lRow[0])>4) and (lCaseCount > 0) then
            begin
              m('ERROR: This program is not coded to handle unicode characters outside of the BMP (Basic Multilingual Plane)');
              break;
            end;

            if lCaseCount = 0 then
            begin
              m('ERROR: no matching case. '+lFile.Strings[i]);
              break;
            end
            else if lCaseCount = 1 then
            begin
              lMappings[lCode].description := lRow[1]+' '+lRow[10];
              lMappings[lCode].Char1 := StrToInt('$'+lCase[0]);
              lPageCounts1[lCode shr 8] := lPageCounts1[lCode shr 8] + 1;
            end
            else if lCaseCount = 2 then
            begin
              lMappings[lCode].description := lRow[1]+' '+lRow[10];
              lMappings[lCode].Char1 := StrToInt('$'+lCase[0]);
              lMappings[lCode].Char2 := StrToInt('$'+lCase[1]);
              lPageCounts1[lCode shr 8] := lPageCounts1[lCode shr 8] + 1;
              lPageCounts2[lCode shr 8] := lPageCounts2[lCode shr 8] + 1;
              m('Dual Mapping: '+lFile.Strings[i]);
            end
            else
            begin
              m('ERROR: matched 3 cases which is too many. '+lFile.Strings[i]);
            end;
          end
          else
          begin
            // no matching upper/lower case pairing
            lMappings[lCode].description := lRow[1]+' '+lRow[10];
          end;
        end;
      end;
    end;


    // now that we have finished parsing the input file, publish our results to a pascal source code file
    wf('unit unicodeData;');
    wf('');
    wf('(* This file was produced by UnicodeDataProcessor.exe which is an application that reads the unicodeData.txt produced by');
    wf('   The Unicode Consortium.  See http://www.unicode.org.');
    wf('   Specifically, the file we are reading is from https://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt');
    wf('   Generated on '+DateTimeToStr(now));
    wf('');
    wf('   The code that produces this file can be found at:  https://github.com/SeanSolberg/CompareTextUnicode');
    wf('*)');
    wf('');
    ProduceLicenseText;
    wf('');

    wf('interface');

(*  DEPRECATED - This is my first set of logic in this code where I built a full table which gave me a single jump into the table to lookup a pairing.
                 It's performance was good, but it created a 250K table that most mostly zeros.  Huge waste.  So, I eliminated this single table method
                 and created a two-step method instead below.

    // Publish a full table
    wf('');
    wf('const');
    wf('  cUnicodeCharacterPairs: array[0..65535] of longInt = (');
    for i := low(lMappings) to High(lMappings) do
    begin
      lStr := '$'+intToHex(lMappings[i].Char2,4)+intToHex(lMappings[i].Char1,4);
      if i = high(lMappings) then
        lStr := lStr + ' '
      else
        lStr := lStr + ',';
      lStr := lStr+'    // $'+intToHex(i,4) + ' '+lMappings[i].description;
      wf(lStr);
    end;
    wf('  );');
 *)




    //publish the two paging index arrays.  They hold a pairing count for each page.
    m('Index one counts');
    for i := 0 to 15 do
    begin
      lStr := '';
      for j := 0 to 15 do
      begin
        lStr := lStr + ' ' + intToStr(lPageCounts1[i shl 4 + j]);
      end;
      m(lStr);
    end;
    m('');
    m('Index two counts');
    for i := 0 to 15 do
    begin
      lStr := '';
      for j := 0 to 15 do
      begin
        lStr := lStr + ' ' + intToStr(lPageCounts2[i shl 4 + j]);
      end;
      m(lStr);
    end;

    wf('');
    ProduceCompareTextUnicodeInterface;

    wf('');
    wf('implementation');
    wf('');

    {Note that based on the current unicodeData.Txt file, only twenty of the 256 pages actually have any pairings in them for index #1.
     So we don't need to store any lookup data for those pages that don't have any pairs.
     Let's create a 256 byte index where each node in the index stores a tableID.
     Then, when we populate the pairing table(s), we only create tables and index entries for those pages that have some pairings.}
    PublishPairingIndex('cUnicodeCharacterPairsIndex1', 0);   // Note, this calculates lPageCount

    {Now produce our lookup pairing table.
     It is a two dimensional table where the first dimension is the tableId from the tableIndex as created above,
     and the second dimension is the character code within that page (0-255)}
    PublishPairingTable(0, lPageCount);

    {Generate a second pairing table because there are some characters that have up to two pairings.}
    PublishPairingIndex('cUnicodeCharacterPairsIndex2', 1);   // Note, this calculates lPageCount

    {Now produce our lookup pairing table.
     It is a two dimensional table where the first dimension is the tableId from the tableIndex as created above,
     and the second dimension is the character code within that page (0-255)}
    PublishPairingTable(1, lPageCount);

    wf('');
    ProduceCompareTextUnicodeImplementation;

    wf('end.');


//    m('Size1: '+IntTostr(sizeof(cPairingTable1)));
//    m('Size2: '+IntTostr(sizeof(cPairingTable2)));
    m('DONE');

    lOutFile.SaveToFile('..\..\unicodedata.pas');
  finally
    lRow.Free;
    lFile.Free;
    lOutFile.free;
  end;
end;

procedure TForm34.btnPerformanceTestClick(Sender: TObject);
var
  lStr1, lStr2: string;

  procedure Test(aStr1, aStr2, caption: string);
  var
    i: Integer;
    lStart: TDatetime;
  begin
    memo1.Lines.Add(caption);
    lStart := now;
    for i := 0 to 10000000 do
    begin
      compareText(aStr1, aStr2);
    end;
    memo1.Lines.Add('CompareText Time: '+FloatToStr((now-lStart)*24*60*60));

    lStart := now;
    for i := 0 to 10000000 do
    begin
      compareTextUnicode(aStr1, aStr2);
    end;
    memo1.Lines.Add('CompareTextUnicode Time: '+FloatToStr((now-lStart)*24*60*60));
    memo1.Lines.Add('');
  end;

begin
  // This method compares a few performance tests by calling the System.SysUtils.compareText
  // function and the new comcpareTextUnicode function ten million times.
  // If I use the strict pascal version of compareText then the performance is very close between the two functions
  // when both functions are getting a true result with mixed cases.
  // when the compareText function breaks out early because it's not properly comparing certain unicode case pairs, of course it's faster (but that's cause it's wrong and breaking out early)
  // However, the assembly version of compareText is much faster so it would be nice to take the compareTextUnicode function and make an assembly version.

  Test('Hello World','HELLO WORLD', 'Different case with both comparing to true.');
  Test('Hell'#$f4' World','HELL'#$d4' WORLD', 'Different case.  compareText gets false, compareTextUnicode gets true.');    // Letter 0 with circumflex comparing capital to lower case
  Test('HELLO WORLD', 'HELLO WORLD', 'Two identical texts.');    // Letter 0 with circumflex comparing capital to lower case
end;

procedure TForm34.btnTestClick(Sender: TObject);

  procedure Test(aStr1, aStr2: string);
  var
    lRes,lRes2: integer;
  begin
    lRes := CompareText(aStr1, aStr2);
    lRes2 := CompareTextUnicode(aStr1, aStr2);

    if lRes = lRes2 then
    begin
      memo1.Lines.Add('SAME ANSWERS: '+IntTostr(lRes)+': "'+aStr1+'", "'+aStr2+'"')
    end
    else
    begin
      memo1.Lines.Add('DIFFERENT ANSWERS: CompareText '+IntTostr(lRes)+' & CompareTextUnicode '+IntTostr(lRes2)+': "'+aStr1+'", "'+aStr2+'"');
    end;
  end;

begin
  Test('Hello World', 'HELLO WORLD');   // normal ascii space
  Test('ello World ', 'ELLO WORLD');   // normal ascii space
  Test('Hello World ', 'HELLO WORLD');   // normal ascii space
  Test('Hello World', 'HELLO WORLD ');   // normal ascii space
  Test('Hello World  ', 'HELLO WORLD');   // normal ascii space
  Test('Hello World', 'HELLO WORLD  ');   // normal ascii space

  Test('Hell'#$f4' World', 'HELL'#$d4' WORLD');  // Letter 0 with circumflex comparing capital to lower case

  Test(#$127'ello World', #$126'ELLO WORLD');   // Letter H with Stroke
  Test(#$127'ello World', #$126'ELLO WORLD ');   // Letter H with Stroke
  Test(#$127'ello World ', #$126'ELLO WORLD');   // Letter H with Stroke

  {  this test tries out the 2nd pairing table (which only has one page and very few pairings)
  01C4;LATIN CAPITAL LETTER DZ WITH CARON;Lu;0;L;<compat> 0044 017D;;;;N;LATIN CAPITAL LETTER D Z HACEK;;;01C6;01C5
  01C5;LATIN CAPITAL LETTER D WITH SMALL LETTER Z WITH CARON;Lt;0;L;<compat> 0044 017E;;;;N;LATIN LETTER CAPITAL D SMALL Z HACEK;;01C4;01C6;01C5
  01C6;LATIN SMALL LETTER DZ WITH CARON;Ll;0;L;<compat> 0064 017E;;;;N;LATIN SMALL LETTER D Z HACEK;;01C4;;01C5
  }
  Test(#$01C4#$01C4#$01C5#$01C5#$01C6#$01C6, #$01C5#$01C6#$01C4#$01C6#$01C4#$01C5);
end;



procedure TForm34.btnTestCompareTextClick(Sender: TObject);
  procedure test(aStr1, aStr2: string);
  var
    lResult: integer;
  begin
    lResult := CompareText(aStr1, aStr2);
    if lResult = 0 then
      memo1.Lines.Add('SAME: "'+aStr1+'", "'+aStr2+'"')
    else
      memo1.Lines.Add('DIFFERENT: '+InttoStr(lResult)+' "'+aStr1+'", "'+aStr2+'"');
  end;
begin
  // This function does some basic testing of the System.SysUtils.CompareText function
  // While working on the improved compareTextUnicode function, I found that the standard compareText function
  // does not return consistent results depending on whether you have an odd number of characters or an even number of characters
  // That's because internally, that function is trying to be efficient so it processes two characters (4-bytes) at a time.  This means
  // that if you have two test strings that are equal up to the point where one of the strings is then longer that the other, and if
  // the test string has an odd number of characters, then the 2nd character in a comparison pass is compared against null. giving a result
  // number that is the difference between the last character and null.  If if the string has an even number of characters under the same
  // condition above, then the last comparison isn't to null so the code returns a size difference between the strings.
  // Note that the defined behavior is to return a negative number, positive number or zero so this logic still holds to the defininion.  It's
  // just kind of wierd to have different result values depending on whether there is an even number or odd number of characters.
  // This test basically just shows this.

  test('Hello World', 'HELLO WORLD ');
  test('Hello World ', 'HELLO WORLD');
  test('Hello World ', 'HELLO WORLD ');
  memo1.Lines.Add('');

  test('ello World', 'ELLO WORLD ');
  test('ello World ', 'ELLO WORLD');
  test('ello World ', 'ELLO WORLD ');
  memo1.Lines.Add('');

  test('HELLO WORLD ', 'Hello World');
  test('HELLO WORLD', 'Hello World ');
  test('HELLO WORLD ', 'Hello World ');
end;

(* DEPRECATED
function CompareTextUnicode(const S1, S2: string): Integer;
var
  I, Last, L1, L2, C1, C2, Ch1, Ch2, lPairing, lPair1, lPair2: Cardinal;
begin
  L1 := Length(S1);
  L2 := Length(S2);
  result := L1 - L2;
  if (L1 > 0) and (L2 > 0) then
  begin
    if result < 0 then Last := L1 shl 1
    else Last := L2 shl 1;

    I := 0;
    while I < Last do
    begin
      C1 := PInteger(PByte(S1) + I)^;
      C2 := PInteger(PByte(S2) + I)^;
      if C1 <> C2 then
      begin
        { Compare first char}
        Ch1 := C1 and $0000FFFF;
        Ch2 := C2 and $0000FFFF;
        if Ch1 <> Ch2 then
        begin
          // Lookup the corresponding two possible case comparisons and compare to the second character
          lPairing := cUnicodeCharacterPairs[Ch1];
          if lPairing <> 0 then
          begin
            lPair1 := lPairing and $0000FFFF;
            if (Ch2 <> lPair1) then
            begin
              lPair2 := lPairing shr 16;
              if (lPair2 <> 0) and (Ch2 <> lPair2) then
                Exit(Ch1 - Ch2);
            end;
          end
          else
          begin
            // no pairing found for the lookup character code so characters must be different.
            Exit(Ch1 - Ch2);
          end;
        end;

        { Compare second }
        Ch1 := (C1 and $FFFF0000) shr 16;
        Ch2 := (C2 and $FFFF0000) shr 16;
        if Ch1 <> Ch2 then
        begin
          // Lookup the corresponding two possible case comparisons and compare to the second character
          lPairing := cUnicodeCharacterPairs[Ch1];
          if lPairing <> 0 then
          begin
            lPair1 := lPairing and $0000FFFF;
            if (Ch2 <> lPair1) then
            begin
              lPair2 := lPairing shr 16;
              if (lPair2 <> 0) and (Ch2 <> lPair2) then
                Exit(Ch1 - Ch2);
            end;
          end
          else
          begin
            // no pairing found for the lookup character code so characters must be different.
            Exit(Ch1 - Ch2);
          end;
        end;
      end;
      inc(I, 4);
    end;
  end;
end;

*)


(*
// This version of this function uses paged pairing tables with an index lookup into the right table through the index.
// The index and the pairing tables are defined in unicodeData.pas which is generated by this program.
// Note that the general flow of this code is cloned from sysUtils.pas
function CompareTextUnicode(const S1, S2: string): Integer;
var
  I, Last, L1, L2: cardinal;
  Ch1, Ch2, lPairedCh: word;
  lIndex: byte;
begin
  L1 := Length(S1);
  L2 := Length(S2);
  result := L1 - L2;
  if (L1 > 0) and (L2 > 0) then
  begin
    if result < 0 then Last := L1 shl 1
    else Last := L2 shl 1;

    I := 0;
    while I < Last do
    begin
      Ch1 := PWord(PByte(S1) + I)^;
      Ch2 := PWord(PByte(S2) + I)^;

      if Ch1 <> Ch2 then
      begin
        // Lookup the corresponding first possible pairing and compare to the second character
        lIndex := cUnicodeCharacterPairsIndex1[Ch1 shr 8];      // Lookup the index value. If it is zero, then there's no associated table to bother looking into.
        if lIndex <> 0 then
        begin
          lPairedCh := cPairingTable1[lIndex-1,Ch1 and $FF];
          if (lPairedCh <> 0) then
          begin
            if (Ch2 <> lPairedCh) then
            begin
              // Ch2 did not match the found paired Character from Ch1, so try to look into the secondary pairing table
              lIndex := cUnicodeCharacterPairsIndex2[Ch1 shr 8];      // Lookup the index value. If it is zero, then there's no associated table to bother looking into.
              if lIndex <> 0 then
              begin
                lPairedCh := cPairingTable2[lIndex-1, Ch1 and $FF];
                if lPairedCh <> 0 then
                begin
                  if (Ch2 <> lPairedCh) then
                  begin
                    // at this point we checked both pairingTable1 and pairingTable2 but didn't get a match.  consider Ch1 and Ch2 different
                    Exit(Ch1 - Ch2);
                  end;
                end
                else
                begin
                  // no pairing found for the lookup character code so they must be different
                  Exit(Ch1 - Ch2);
                end;
              end
              else
              begin
                // no page index found for the lookup character code so characters must be different.
                Exit(Ch1 - Ch2);
              end;
            end;
          end
          else
          begin
            // no pairing found for the lookup character code so they must be different
            Exit(Ch1 - Ch2);
          end;
        end
        else
        begin
          // no page index found for the lookup character code so characters must be different.
          Exit(Ch1 - Ch2);
        end;
      end;

      inc(I, 2);
    end;
  end;
end;

*)

end.
