# CompareTextUnicode
Delphi's System.SysUtils.CompareText function doesn't consider all unicode lowerCase-to-upperCase pairs.
This code implements a CompareTextUnicode function that is based on a small set of constant lookup tables
from the official data files produced by unicode.org.


