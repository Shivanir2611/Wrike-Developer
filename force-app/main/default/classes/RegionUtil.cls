public class RegionUtil {
    public static String getRegionByCountryCode(final String countryCode) {
        if(String.isNotBlank(countryCode) && countryCode.length() == 2) {
            if('AO,BF,BI,BJ,BW,CD,CF,CG,CI,CM,CV,DJ,EH,ER,ET,GA,GH,GM,GN,GQ,GW,KE,KM,LR,LS,LY,MG,ML,MR,MU,MW,MZ,NA,NE,NG,RE,RW,SC,SH,SL,SN,SO,SS,ST,SZ,TD,TG,TZ,UG,YT,ZM,ZW,ZZ'.contains(countryCode)) {
                return 'Africa';
            } else if('AF,BD,BT,CC,CN,CX,FM,IN,KP,LK,MH,MN,MP,MV,NP,NR,NU,PF,PK,PW,TK,TO,TW,WF'.contains(countryCode)) {
                return 'Asia';
            } else if('BR' == countryCode) {
                return 'Brazil';    
            } else if('AL,BA,BG,CS,CY,CZ,EE,GR,HR,HU,LT,LV,ME,MK,PL,RO,RS,SI,SK,XK'.contains(countryCode)) {
                return 'Eastern Europe';
            } else if('AT,CH,DE,LI'.contains(countryCode)) {
                return 'DACH';
            } else if('AD,BE,DZ,FR,LU,MA,MC,TN'.contains(countryCode)) {
                return 'French';
            } else if('IT,SM,VA'.contains(countryCode)) {
                return 'Italy';
            } else if('HK,JP,KR,MO,SG'.contains(countryCode)) {
                return 'Japan';
            } else if('AG,AI,AN,AR,AW,BB,BL,BO,BQ,BS,BZ,CL,CO,CR,CU,CW,DM,DO,EC,FK,GD,GF,GP,GT,GY,HN,HT,JM,KI,KN,LC,MF,MQ,MS,MX,NI,PA,PE,PN,PR,PY,SR,SV,SX,TC,TT,TV,UY,VC,VE,VI'.contains(countryCode)) {
                return 'LatAm';
            } else if('AE,BH,EG,IQ,IR,JO,KW,LB,OM,PS,QA,SA,SD,SY,TR,YE'.contains(countryCode)) {
                return 'Middle East';
            } else if('BM,CA,KY,US'.contains(countryCode)) {
                return 'North America';
            } else if('AX,DK,FI,FO,GL,IS,NL,NO,SE,SJ'.contains(countryCode)) {
                return 'Nordics';
            } else if('AQ,AS,AU,CK,FJ,IO,NC,NZ,SB,UM,VU,WS'.contains(countryCode)) {
                return 'NZ/AU';
            } else if('AM,AZ,BY,GE,KG,KZ,MD,RU,TJ,TM,UA,UZ'.contains(countryCode)) {
                return 'Russo';
            } else if('BN,GU,ID,KH,LA,MM,MY,PG,PH,TH,TL,VN'.contains(countryCode)) {
                return 'SEA';
            } else if('ES,PT'.contains(countryCode)) {
                return 'Spain';
            } else if('GB,GG,GI,IE,IL,IM,JE,MT,PM,VG,ZA'.contains(countryCode)) {
                return 'GB/IE/Israel/SoAfrica';
            }
        }
        return 'Other';
    }
}