(*
*=================================================================================
* Unit for base module for Jusolink API SDK. It include base functionality for
* RESTful web service request and parse json result. It uses Linkhub module
* to accomplish authentication APIs.
*
* This module uses synapse library.( http://www.ararat.cz/synapse/doku.php/ )
* It's full open source library, free to use include commercial application.
* If you wish to donate that, visit their site.
* So, before using this module, you need to install synapse by user self.
* You can refer their site or detailed infomation about installation is available
* from below our site. We appreciate your visiting.
*
* For strongly secured communications, this module uses SSL/TLS with OpenSSL.
* So You need two dlls (libeay32.dll and ssleay32.dll) from OpenSSL. You can
* get it from Fulgan. ( http://indy.fulgan.com/SSL/ ) We recommend i386_win32 version.
* And also, dlls must be released with your executions. That's the drawback of this
* module, but we acommplished higher security level against that.
*
* http://jusolink.com
* Author : Jeong Yohan (yhjeong@linkhub.co.kr)
* Written : 2015-05-07
* Thanks for your interest.
*=================================================================================
*)
unit Jusolink;

interface
uses
        Windows, Messages, TypInfo, SysUtils, synautil, synachar, Classes, HTTPSend, ssl_openssl, Linkhub;

{$IFDEF VER240}
{$DEFINE COMPILER15_UP}
{$ENDIF}
{$IFDEF VER250}
{$DEFINE COMPILER15_UP}
{$ENDIF}
{$IFDEF VER260}
{$DEFINE COMPILER15_UP}
{$ENDIF}
{$IFDEF VER270}
{$DEFINE COMPILER15_UP}
{$ENDIF}
{$IFDEF VER280}
{$DEFINE COMPILER15_UP}
{$ENDIF}
const
        ServiceID = 'JUSOLINK';
        ServiceURL = 'https://juso.linkhub.co.kr';
        APIVersion = '1.0';
        CR = #$0d;
        LF = #$0a;
        CRLF = CR + LF;
type
        TResponse = Record
                code : LongInt;
                message : string;
        end;

        TSidoCount = class
        public
             GYEONGGI                  : Integer;
             GYEONGSANGBUK             : Integer;
             GYEONGSANGNAM             : Integer;
             SEOUL                     : Integer;
             JEOLLANAM                 : Integer;
             CHUNGCHEONGNAM            : Integer;
             JEOLLABUK                 : Integer;
             BUSAN                     : Integer;
             GANGWON                   : Integer;
             CHUNGCHEONGBUK            : Integer;
             DAEGU                     : Integer;
             INCHEON                   : Integer;
             GWANGJU                   : Integer;
             JEJU                      : Integer;
             DAEJEON                   : Integer;
             ULSAN                     : Integer;
             SEJONG                    : Integer;
        end;

        TJusoInfo = class
        public
                roadAddr1               : string;
                roadAddr2               : string;
                jibunAddr               : string;
                zipcode                 : string;
                sectionNum              : string;
                detailBuildingName      : ArrayOfString;
                relatedJibun            : ArrayOfString;
                dongCode                : string;
                streetCode              : string;

        end;

        TSearchResult = class
                searches                : string;
                deletedWord             : ArrayOfString;
                suggest                 : string;
                numFound                : Integer;
                listSize                : Integer;
                totalPage               : Integer;
                page                    : Integer;
                chargeYN                : Boolean;
                juso                    : Array Of TJusoInfo;
                sidoCount               : TSidoCount
        end;

        TJusolinkService = class

        private
                function jsonToTSearchResult(json : String) : TSearchResult;

        protected
                FToken  : TToken;
                FAuth   : TAuth;
                FScope  : Array of String;

                function getSession_Token() : String;
                function httpget(url : String) : String;

        public
                constructor Create(LinkID : String; SecretKey : String);
                function GetBalance() : Double;
                function GetUnitCost() : Single;
                function search(Index : String; PageNum : Integer) : TSearchResult;overload;
                function search(Index : String; PageNum : Integer; PerPage : Integer) : TSearchResult;overload;
                function search(Index : String; PageNum : Integer; PerPage : Integer; noSuggest : Boolean; noDiff : Boolean) : TSearchResult;overload;
        end;

        EJusolinkException = class(Exception)

        private
                FCode : LongInt;
        public
                constructor Create(code : LongInt; Message : String);
        published
                property code : LongInt read FCode write FCode;

        end;

implementation


constructor EJusolinkException.Create(code : LongInt; Message : String);
begin
    inherited Create(Message);
    FCode := code;
end;

constructor TJusolinkService.Create(LinkID : String; SecretKey : String);
begin
        FAuth := TAuth.Create(LinkID, SecretKey);
        setLength(FScope, 1);
        FScope[0] := '200';
end;


function TJusolinkService.getSession_Token() : String;
var
        noneOrExpired : bool;
        Expiration : TDateTime;
begin
        if FToken = nil then noneOrExpired := true
        else begin
                Expiration := UTCToDate(FToken.expiration);
                noneOrExpired := expiration < now;
        end;

        if noneOrExpired then
        begin
                try
                        FToken := FAuth.getToken(ServiceID,'',FScope);
                except on le:ELinkhubException do
                        raise EJusolinkException.Create(le.code,le.message);
                end;
        end;
        result := FToken.session_token;
end;

function TJusolinkService.httpget(url : String) : String;
var
        HTTP: THTTPSend;
        response : string;
        sessiontoken : string;
begin
        url := ServiceURL + url;

        HTTP := THTTPSend.Create;
        HTTP.Sock.SSLDoConnect;

        sessiontoken := getSession_Token();

        HTTP.Headers.Add('Authorization: Bearer ' + sessiontoken);
        HTTP.Headers.Add('x-api-version: ' + APIVersion);


        try
                if HTTP.HTTPMethod('GET', url) then
                begin
                        if HTTP.ResultCode <> 200 then
                        begin
                                response := StreamToString(HTTP.Document);
                                raise EJusolinkException.Create(getJSonInteger(response,'code'),getJSonString(response,'message'));
                        end;
                        result := StreamToString(HTTP.Document);

                end
                else
                begin
                    if HTTP.ResultCode <> 200 then
                    begin
                        raise EJusolinkException.Create(-99999999,HTTP.ResultString);
                    end;
                end;

        finally
                HTTP.Free;
        end;
end;

function UrlEncodeUTF8(stInput : widestring) : string;
  const
    hex : array[0..255] of string = (
     '%00', '%01', '%02', '%03', '%04', '%05', '%06', '%07',
     '%08', '%09', '%0a', '%0b', '%0c', '%0d', '%0e', '%0f',
     '%10', '%11', '%12', '%13', '%14', '%15', '%16', '%17',
     '%18', '%19', '%1a', '%1b', '%1c', '%1d', '%1e', '%1f',
     '%20', '%21', '%22', '%23', '%24', '%25', '%26', '%27',
     '%28', '%29', '%2a', '%2b', '%2c', '%2d', '%2e', '%2f',
     '%30', '%31', '%32', '%33', '%34', '%35', '%36', '%37',
     '%38', '%39', '%3a', '%3b', '%3c', '%3d', '%3e', '%3f',
     '%40', '%41', '%42', '%43', '%44', '%45', '%46', '%47',
     '%48', '%49', '%4a', '%4b', '%4c', '%4d', '%4e', '%4f',
     '%50', '%51', '%52', '%53', '%54', '%55', '%56', '%57',
     '%58', '%59', '%5a', '%5b', '%5c', '%5d', '%5e', '%5f',
     '%60', '%61', '%62', '%63', '%64', '%65', '%66', '%67',
     '%68', '%69', '%6a', '%6b', '%6c', '%6d', '%6e', '%6f',
     '%70', '%71', '%72', '%73', '%74', '%75', '%76', '%77',
     '%78', '%79', '%7a', '%7b', '%7c', '%7d', '%7e', '%7f',
     '%80', '%81', '%82', '%83', '%84', '%85', '%86', '%87',
     '%88', '%89', '%8a', '%8b', '%8c', '%8d', '%8e', '%8f',
     '%90', '%91', '%92', '%93', '%94', '%95', '%96', '%97',
     '%98', '%99', '%9a', '%9b', '%9c', '%9d', '%9e', '%9f',
     '%a0', '%a1', '%a2', '%a3', '%a4', '%a5', '%a6', '%a7',
     '%a8', '%a9', '%aa', '%ab', '%ac', '%ad', '%ae', '%af',
     '%b0', '%b1', '%b2', '%b3', '%b4', '%b5', '%b6', '%b7',
     '%b8', '%b9', '%ba', '%bb', '%bc', '%bd', '%be', '%bf',
     '%c0', '%c1', '%c2', '%c3', '%c4', '%c5', '%c6', '%c7',
     '%c8', '%c9', '%ca', '%cb', '%cc', '%cd', '%ce', '%cf',
     '%d0', '%d1', '%d2', '%d3', '%d4', '%d5', '%d6', '%d7',
     '%d8', '%d9', '%da', '%db', '%dc', '%dd', '%de', '%df',
     '%e0', '%e1', '%e2', '%e3', '%e4', '%e5', '%e6', '%e7',
     '%e8', '%e9', '%ea', '%eb', '%ec', '%ed', '%ee', '%ef',
     '%f0', '%f1', '%f2', '%f3', '%f4', '%f5', '%f6', '%f7',
     '%f8', '%f9', '%fa', '%fb', '%fc', '%fd', '%fe', '%ff');
 var
   iLen,iIndex : integer;
   stEncoded : string;
   ch : widechar;
 begin
   iLen := Length(stInput);
   stEncoded := '';
   for iIndex := 1 to iLen do
   begin
     ch := stInput[iIndex];
     if (ch >= 'A') and (ch <= 'Z') then
       stEncoded := stEncoded + ch
     else if (ch >= 'a') and (ch <= 'z') then
       stEncoded := stEncoded + ch
     else if (ch >= '0') and (ch <= '9') then
       stEncoded := stEncoded + ch
     else if (ch = ' ') then
       stEncoded := stEncoded + '+'
     else if ((ch = '-') or (ch = '_') or (ch = '.') or (ch = '!') or (ch = '*')
       or (ch = '~') or (ch = '\')  or (ch = '(') or (ch = ')')) then
       stEncoded := stEncoded + ch
     else if (Ord(ch) <= $07F) then
       stEncoded := stEncoded + hex[Ord(ch)]
     else if (Ord(ch) <= $7FF) then
     begin
        stEncoded := stEncoded + hex[$c0 or (Ord(ch) shr 6)];
        stEncoded := stEncoded + hex[$80 or (Ord(ch) and $3F)];
     end
     else
     begin
        stEncoded := stEncoded + hex[$e0 or (Ord(ch) shr 12)];
        stEncoded := stEncoded + hex[$80 or ((Ord(ch) shr 6) and ($3F))];
        stEncoded := stEncoded + hex[$80 or ((Ord(ch)) and ($3F))];
     end;
   end;
   result := (stEncoded);
 end;

function TJusolinkService.jsonToTSearchResult(json : String) : TSearchResult;
var
        jSons : ArrayOfString;
        jSonsDetailBuilding : ArrayOfString;
        jSonsRelatedJibun : ArrayOfString;
        jSonSidoCount : ArrayOfString;
        i : Integer;
        j : Integer;

begin
        result := TSearchResult.Create;
        result.searches := getJsonString(json, 'searches');

        try
                jSons := getJsonList(json,'deletedWord');
                SetLength(result.deletedWord, Length(jSons));

                for i:= 0 to Length(jSons)-1 do
                begin
                        result.deletedWord[i] := jSons[i];
                end;

        except on E:Exception do
                raise EJusolinkException.Create(-99999999,'error');
        end;

        result.suggest := getJsonString(json, 'suggest');
        result.numFound := getJsonInteger(json, 'numFound');
        result.listSize := getJsonInteger(json, 'listSize');
        result.totalPage := getJsonInteger(json, 'totalPage');
        result.page := getJsonInteger(json, 'page');
        result.chargeYN := getJsonBoolean(json, 'chargeYN');

        result.sidoCount := TSidoCount.Create;
        if Length(getJsonList(json, 'sidoCount')) >0  then
        begin
                jsonSidoCount := getJsonList(json, 'sidoCount');
                if getJsonInteger(jSonSidoCount[0], 'GYEONGGI') > 0 then result.sidoCount.GYEONGGI := getJsonInteger(jSonSidoCount[0], 'GYEONGGI');
                if getJsonInteger(jSonSidoCount[0], 'GYEONGSANGBUK') > 0 then result.sidoCount.GYEONGSANGBUK := getJsonInteger(jSonSidoCount[0], 'GYEONGSANGBUK');
                if getJsonInteger(jSonSidoCount[0], 'GYEONGSANGNAM') > 0 then result.sidoCount.GYEONGSANGNAM := getJsonInteger(jSonSidoCount[0], 'GYEONGSANGNAM');
                if getJsonInteger(jSonSidoCount[0], 'SEOUL') > 0 then result.sidoCount.SEOUL := getJsonInteger(jSonSidoCount[0], 'SEOUL');
                if getJsonInteger(jSonSidoCount[0], 'JEOLLANAM') > 0 then result.sidoCount.JEOLLANAM := getJsonInteger(jSonSidoCount[0], 'JEOLLANAM');
                if getJsonInteger(jSonSidoCount[0], 'CHUNGCHEONGNAM') > 0 then result.sidoCount.CHUNGCHEONGNAM := getJsonInteger(jSonSidoCount[0], 'CHUNGCHEONGNAM');
                if getJsonInteger(jSonSidoCount[0], 'JEOLLABUK') > 0 then result.sidoCount.JEOLLABUK := getJsonInteger(jSonSidoCount[0], 'JEOLLABUK');
                if getJsonInteger(jSonSidoCount[0], 'BUSAN') > 0 then result.sidoCount.BUSAN := getJsonInteger(jSonSidoCount[0], 'BUSAN');
                if getJsonInteger(jSonSidoCount[0], 'GANGWON') > 0 then result.sidoCount.GANGWON := getJsonInteger(jSonSidoCount[0], 'GANGWON');
                if getJsonInteger(jSonSidoCount[0], 'CHUNGCHEONGBUK') > 0 then result.sidoCount.CHUNGCHEONGBUK := getJsonInteger(jSonSidoCount[0], 'CHUNGCHEONGBUK');
                if getJsonInteger(jSonSidoCount[0], 'DAEGU') > 0 then result.sidoCount.DAEGU := getJsonInteger(jSonSidoCount[0], 'DAEGU');
                if getJsonInteger(jSonSidoCount[0], 'INCHEON') > 0 then result.sidoCount.INCHEON := getJsonInteger(jSonSidoCount[0], 'INCHEON');
                if getJsonInteger(jSonSidoCount[0], 'GWANGJU') > 0 then result.sidoCount.GWANGJU := getJsonInteger(jSonSidoCount[0], 'GWANGJU');
                if getJsonInteger(jSonSidoCount[0], 'JEJU') > 0 then result.sidoCount.JEJU := getJsonInteger(jSonSidoCount[0], 'JEJU');
                if getJsonInteger(jSonSidoCount[0], 'DAEJEON') > 0 then result.sidoCount.DAEJEON := getJsonInteger(jSonSidoCount[0], 'DAEJEON');
                if getJsonInteger(jSonSidoCount[0], 'ULSAN') > 0 then result.sidoCount.ULSAN := getJsonInteger(jSonSidoCount[0], 'ULSAN');
                if getJsonInteger(jSonSidoCount[0], 'SEJONG') > 0 then result.sidoCount.SEJONG := getJsonInteger(jSonSidoCount[0], 'SEJONG');
        end;

        try
                jSons := getJsonListString(json, 'juso');

                SetLength(result.juso, Length(jSons));

                for i:= 0 to Length(jSons)-1 do

                begin
                        result.juso[i] := TJusoInfo.Create;
                        result.juso[i].roadAddr1 := getJsonString(jSons[i], 'roadAddr1');
                        result.juso[i].roadAddr2 := getJsonString(jSons[i], 'roadAddr2');
                        result.juso[i].jibunAddr := getJsonString(jSons[i], 'jibunAddr');
                        result.juso[i].zipcode := getJsonString(jSons[i], 'zipcode');
                        result.juso[i].sectionNum := getJsonString(jSons[i], 'sectionNum');
                        result.juso[i].dongCode := getJsonString(jSons[i], 'dongCode');
                        result.juso[i].streetCode := getJsonString(jSons[i], 'streetCode');

                        SetLength(jSonsDetailBuilding, 0);                                                                          
                        jSonsDetailBuilding := getJsonList(jSons[i], 'detailBuildingName');

                        SetLength(result.juso[i].detailBuildingName, Length(jSonsDetailBuilding));

                        for j:= 0 to Length(jSonsDetailBuilding)-1 do
                        begin
                                result.juso[i].detailBuildingName[j] := jSonsDetailBuilding[j];
                        end;

                        SetLength(jSonsRelatedJibun, 0);
                        jSonsRelatedJibun := getJsonList(jSons[i], 'relatedJibun');

                        SetLength(result.juso[i].relatedJibun, Length(jSonsRelatedJibun));

                        for j:= 0 to Length(jSonsRelatedJibun)-1 do
                        begin
                                result.juso[i].relatedJibun[j] := jSonsRelatedJibun[j];
                        end;
                        
                end;

        except on E:Exception do
                raise EJusolinkException.Create(-99999999, '결과 처리 실패. [Malformed Json]');
        end;
end;

function TJusolinkService.GetBalance() : Double;
begin
        result := FAuth.getPartnerBalance(getSession_Token(),ServiceID);
end;

function TJusolinkService.GetUnitCost() : Single;
var
        responseJson : string;

begin
        responseJson := httpget('/Search/UnitCost');

        result := strToFloat(getJsonString(responseJson,'unitCost'));
end;


function TJusolinkService.search(Index : String; PageNum : Integer) : TSearchResult;
begin
        result := search(Index, PageNum, 20);
end;

function TJusolinkService.search(Index : String; PageNum : Integer; PerPage : Integer) : TSearchResult;
begin
        result := search(Index, PageNum, 20, false, false);
end;

function TJusolinkService.search(Index : String; PageNum : Integer; PerPage : Integer; noSuggest : Boolean; noDiff : Boolean) : TSearchResult;
var
        responseJson : string;
        url : string;
begin
        url := '/Search?Searches='+ UrlEncodeUTF8(Index);

        if PerPage < 0 then PerPage := 20;

        if PageNum > 0 then
                url := url + '&&PageNum='+IntToStr(PageNum);

        if PerPage > 0 then
                url := url + '&&PerPage='+IntToStr(PerPage);

        if noSuggest then
                url := url + '&&noSuggest=true';

        if noDiff then
                url :=url + '&&noDifferential=true';

        responseJson := httpget(url);

        result := jsonToTSearchResult(responseJson);
end;
end.
