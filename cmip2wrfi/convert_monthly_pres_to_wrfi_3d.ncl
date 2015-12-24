;*************************************************
; NCL tutorial script: vert_1.ncl
;************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/popRemap.ncl"
external WRITEINT "./src/write_intermediate.so"
;************************************************
begin

;***********************************************
; these should be command line args
;***********************************************

; rcp = rcp85
; model_name = "cesm5-cam1"  ;example model name
;
;
;
;
;************************************
; also setup number of times to process
;*********************************

if (rcp .eq. "historical") then
  CASE = "20THC"
  years = 30
  nmonths = 30*12-1
end if

if (rcp .eq. "rcp26") then
  CASE = "RCP26"
end if

if (rcp .eq. "rcp45") then
  CASE = "RCP45"
end if

if (rcp .eq. "rcp60") then
  CASE = "RCP60"
end if

if (rcp .eq. "rcp85") then
  CASE = "RCP85"
  years = 30
  nmonths = 30*12-1
end if

;************************************************
; file handling
;************************************************
 print("opening files")
   in_ta  = addfile("atmos_ta.nc","r")  ; monthly 3-d T
   in_ua  = addfile("atmos_ua.nc","r")   ; monthly 3-d U
   in_va  = addfile("atmos_va.nc","r")    ; monthly 3-d V
   in_hus  = addfile("atmos_hus.nc","r")   ; monthly 3-d Q
   in_hur   = addfile("atmos_hur.nc","r")   ; monthly 3-d RH
   in_zsfc  = addfile("atmos_zsfc.nc","r")   ; static surface geopotential
   in_lmask = addfile("atmos_lmask.nc","r")  ; static land mask          -> need to process from land fraction to mask (using 50% threshold in WRF)
   in_ts    = addfile("atmos_ts.nc","r")  ; monthly skin temp
   in_zg    = addfile("atmos_zg.nc","r")    ; monthly geopotential
   in_ps    = addfile("atmos_mslp.nc","r")  ; monthly surface pressure     this file comes in Pa

;variables that are set to constant values in this case
;   in_snw = addfile("atmos_snw_1.nc","r") ; monthly SWE                  -> need to set SWE to zero
;   in_mrlsl = addfile("atmos_mrlsl_1.nc","r") ; monthly soil moisture    -> need to set soil moisture to constant, say 0.05
;   in_tsl   = addfile("atmos_tsl_1.nc","r") ; monthly soil temp          ->  set to 280 K constant
;   in_tos   = addfile("atmos_tos_1.nc","r") ; daily SST                  -> set to 280 K constant
;   in_sic   = addfile("atmos_sic_1.nc","r") ; daily SEAICE               -> set to zero

;************************************************
; read needed variables from file
;************************************************
  print("read variables in")

   time   = in_ta->time

   ntimes_3d = dimsizes(time)
   ntimes_3d = ntimes_3d(0)-1

   time2 = time(ntimes_3d-nmonths:ntimes_3d)
   delete(time)
   time = time2
   delete(time2)

   T = in_ta->ta(ntimes_3d-nmonths:ntimes_3d,:,:,:)
   U = in_ua->ua(ntimes_3d-nmonths:ntimes_3d,:,:,:)
   V = in_va->va(ntimes_3d-nmonths:ntimes_3d,:,:,:)
   Q = in_hus->hus(ntimes_3d-nmonths:ntimes_3d,:,:,:)
   R = in_hur->hur(ntimes_3d-nmonths:ntimes_3d,:,:,:)
   ZG= in_zg->zg(ntimes_3d-nmonths:ntimes_3d,:,:,:)
   LMASK= in_lmask->sftlf

   LMASK = where(LMASK .ge. 0.5 , 1, 0)  ;turn LMASK into an actual mask, not a land fraction


   ZSFC = in_zsfc->orog


;   ZSFC = PHIS/9.81
;   SST_DAY_POP   = in_tos->tos
;   ICE_DAY_POP   = in_sic->aice_d*0.01 ; convert from % to fraction
;  P0 = in_ta->p0   ; value of P0 is 1000.(units=hPa); it is used in both Pa and hPa units below depending on function

   P0 = 1000.       ; value of P0 is 1000.(units=hPa); it is used in both Pa and hPa units below depending on function


   PS   = in_ps->psl

;   PS = T(:,0,:,:)*0.0 + 100000.   ;set PS to constant value for now...
;   PS = where(ismissing(PS),100000.,PS)

   LAT  = in_ta->lat  ; latitude
   LON  = in_ta->lon  ; longitude
   PLEV = in_ta->plev/100. ; pressure levels

;print(PLEV)

;   hyam = in_ta->hyam(::-1)
;   hybm = in_ta->hybm(::-1)
;   hyai = in_ta->hyai(::-1)
;   hybi = in_ta->hybi(::-1)
;  hya_bnds = in_ta->a_bnds
;  hyb_bnds = in_ta->b_bnds
;  hyai = new(dimsizes(hyam)+1,double)
;  hybi = new(dimsizes(hybm)+1,double)
;  hyai(0) = hya_bnds(0,0)
;  hyai(1::) = hya_bnds(:,1)
;  hybi(0) = hyb_bnds(0,0)
;  hybi(1::) = hyb_bnds(:,1)
;   print(hyai)

; get dimensions from dummy variable
  dsizes_x = dimsizes(T)
  ntim     = dsizes_x(0)
  nlev     = dsizes_x(1)
  nlat     = dsizes_x(2)
  nlon     = dsizes_x(3)

; Interpolate SST and SEA ICE fields to CCSM Atmospheric domain from POP Ocean domain
;  SST_DAY = PopLatLon(SST_DAY_POP,"gx1v6","fv0.9x1.25","bilin","da","090309")
;  SST6 = new((/ntim,nlat,nlon/),float) ; create a 6 hourly variable and repeat 4x daily
;  SST6(::4,:,:)=SST_DAY
;  SST6(1::4,:,:)=SST_DAY
;  SST6(2::4,:,:)=SST_DAY
;  SST6(3::4,:,:)=SST_DAY
;  SST6 = where (ismissing(SST6), -1.E30, SST6) ; set missing value to default for METGRID.TBL


;  ICE_DAY = PopLatLon(ICE_DAY_POP,"gx1v6","fv0.9x1.25","bilin","da","090309")
;  ICE6 = new((/ntim,nlat,nlon/),float) ; create a 6 hourly variable and repeat 4x daily
;  ICE6(::4,:,:)=ICE_DAY
;  ICE6(1::4,:,:)=ICE_DAY
;  ICE6(2::4,:,:)=ICE_DAY
;  ICE6(3::4,:,:)=ICE_DAY
;  ICE6 = where (ismissing(ICE6), -1.E30, ICE6) ; set missing value to default for METGRID.TBL


;set SST and ICE to constant values 280 K and 0% respectively
  SST6 = T(:,0,:,:)*0.0 + 280.
  ICE6 = T(:,0,:,:)*0.0

  SST6 = where(ismissing(SST6),280.0,SST6)
  ICE6 = where(ismissing(ICE6),0.0,ICE6)

; read in TS
   time_ts = in_ts->time
   ntimes_ts = dimsizes(time_ts)
   ntimes_ts = ntimes_ts(0)-1

   TSKIN = in_ts->ts(ntimes_ts-nmonths:ntimes_ts,:,:)

   TSKIN = where(ismissing(TSKIN),-1.E30,TSKIN)

;make dummy SNOW, TSOIL and MSOIL

   SNOWW = TSKIN*0.0
   TSOIL = TSKIN
   MSOIL = TSKIN*0.0 + 0.05

;   SNOWW = in_snw->snw
;   TSOIL = in_tsl->tsl
;   MSOIL = in_mrlsl->mrlsl
;   SOILD = in_mrlsl->depth



   ;convert MSOIL from kg m-2 to fraction
;     MSOIL = doubletofloat(MSOIL/(1000.*conform(MSOIL,SOILD,1)))

   ; now make into 6 hourly variables that change every ~30 days
   ; note that a *key* assumption here is that we are working with
   ; data in 3 month chunks each time we run this script!!
   ; note that soil M & T have 15 layers.  We only need the 4 that
   ; most closely correspond to the NOAH LSM 0-10,10-40,40-100,100-200 cm layers.
   ; these were predetermined based on inspection of the layers
   ; they aren't very important because they get spun up anyway...
   TSKIN6   = TSKIN ; dummy
   SNOWW6   = SNOWW ; dummy
   TSOIL1_6 = TSKIN ; dummy
   TSOIL2_6 = TSKIN-2. ; dummy
   TSOIL3_6 = TSKIN-3. ; dummy
   TSOIL4_6 = TSKIN-4. ; dummy
   MSOIL1_6 = MSOIL ; dummy
   MSOIL2_6 = MSOIL ; dummy
   MSOIL3_6 = MSOIL ; dummy
   MSOIL4_6 = MSOIL ; dummy



   TAVGSFC6 = TSKIN6              ; This can be used for inland lakes



;   TSKIN6(0:119,:,:)   = conform(PS(0:119,:,:),  TSKIN(0,:,:),(/1,2/))
;   TSKIN6(120:239,:,:) = conform(PS(120:239,:,:),TSKIN(1,:,:),(/1,2/))
;   TSKIN6(240::,:,:)   = conform(PS(240::,:,:),  TSKIN(2,:,:),(/1,2/))

;   SNOWW6(0:119,:,:)   = conform(PS(0:119,:,:),  SNOWW(0,:,:),(/1,2/))
;   SNOWW6(120:239,:,:) = conform(PS(120:239,:,:),SNOWW(1,:,:),(/1,2/))
;   SNOWW6(240::,:,:)   = conform(PS(240::,:,:),  SNOWW(2,:,:),(/1,2/))

;   TSOIL1_6(0:119,:,:)   = conform(PS(0:119,:,:),  TSOIL(0,2,:,:),(/1,2/))
;   TSOIL1_6(120:239,:,:) = conform(PS(120:239,:,:),TSOIL(1,2,:,:),(/1,2/))
;   TSOIL1_6(240::,:,:)   = conform(PS(240::,:,:),  TSOIL(2,2,:,:),(/1,2/))

;   TSOIL2_6(0:119,:,:)   = conform(PS(0:119,:,:),  TSOIL(0,4,:,:),(/1,2/))
;   TSOIL2_6(120:239,:,:) = conform(PS(120:239,:,:),TSOIL(1,4,:,:),(/1,2/))
;   TSOIL2_6(240::,:,:)   = conform(PS(240::,:,:),  TSOIL(2,4,:,:),(/1,2/))

;   TSOIL3_6(0:119,:,:)   = conform(PS(0:119,:,:),  TSOIL(0,6,:,:),(/1,2/))
;   TSOIL3_6(120:239,:,:) = conform(PS(120:239,:,:),TSOIL(1,6,:,:),(/1,2/))
;   TSOIL3_6(240::,:,:)   = conform(PS(240::,:,:),  TSOIL(2,6,:,:),(/1,2/))

;   TSOIL4_6(0:119,:,:)   = conform(PS(0:119,:,:),  TSOIL(0,8,:,:),(/1,2/))
;   TSOIL4_6(120:239,:,:) = conform(PS(120:239,:,:),TSOIL(1,8,:,:),(/1,2/))
;   TSOIL4_6(240::,:,:)   = conform(PS(240::,:,:),  TSOIL(2,8,:,:),(/1,2/))

;   MSOIL1_6(0:119,:,:)   = conform(PS(0:119,:,:),  MSOIL(0,2,:,:),(/1,2/))
;   MSOIL1_6(120:239,:,:) = conform(PS(120:239,:,:),MSOIL(1,2,:,:),(/1,2/))
;   MSOIL1_6(240::,:,:)   = conform(PS(240::,:,:),  MSOIL(2,2,:,:),(/1,2/))

;   MSOIL2_6(0:119,:,:)   = conform(PS(0:119,:,:),  MSOIL(0,4,:,:),(/1,2/))
;   MSOIL2_6(120:239,:,:) = conform(PS(120:239,:,:),MSOIL(1,4,:,:),(/1,2/))
;   MSOIL2_6(240::,:,:)   = conform(PS(240::,:,:),  MSOIL(2,4,:,:),(/1,2/))

;   MSOIL3_6(0:119,:,:)   = conform(PS(0:119,:,:),  MSOIL(0,6,:,:),(/1,2/))
;   MSOIL3_6(120:239,:,:) = conform(PS(120:239,:,:),MSOIL(1,6,:,:),(/1,2/))
;   MSOIL3_6(240::,:,:)   = conform(PS(240::,:,:),  MSOIL(2,6,:,:),(/1,2/))

;   MSOIL4_6(0:119,:,:)   = conform(PS(0:119,:,:),  MSOIL(0,8,:,:),(/1,2/))
;   MSOIL4_6(120:239,:,:) = conform(PS(120:239,:,:),MSOIL(1,8,:,:),(/1,2/))
;   MSOIL4_6(240::,:,:)   = conform(PS(240::,:,:),  MSOIL(2,8,:,:),(/1,2/))

;  Set missing values to default for METGRID.TBL
   TSOIL1_6 = where (ismissing(TSOIL1_6), -1.E30, TSOIL1_6)
   TSOIL2_6 = where (ismissing(TSOIL2_6), -1.E30, TSOIL2_6)
   TSOIL3_6 = where (ismissing(TSOIL3_6), -1.E30, TSOIL3_6)
   TSOIL4_6 = where (ismissing(TSOIL4_6), -1.E30, TSOIL4_6)

   MSOIL1_6 = where (ismissing(MSOIL1_6), -1.E30, MSOIL1_6)
   MSOIL2_6 = where (ismissing(MSOIL2_6), -1.E30, MSOIL2_6)
   MSOIL3_6 = where (ismissing(MSOIL3_6), -1.E30, MSOIL3_6)
   MSOIL4_6 = where (ismissing(MSOIL4_6), -1.E30, MSOIL4_6)

; Get bottom level temperature for vertical extrapolation
;   TBOT = T(0,:,:)

;  print ("calculate Z")
;  Calculate geopotential height
;   TV = T
;   TV      = T*(1.+0.61*Q)
;   Z = T
;   Z = cz2ccm(PS,PHIS,TV(:,::-1,:,:),P0*100.,hyam,hybm,hyai,hybi)
;   Z = Z(:,::-1,:,:) ;reorder vertical so consistent with T,U,V, and Q (bottom up)

   Z = ZG

;  print ("calculate P")
;  Calculate the pressures on each hybrid level (bottom up)
;   P = T
;   P = pres_hybrid_ccm(PS,P0*100.,hyam,hybm)

;  print("calculate RH")
;  Uses stock RH function in ncl
;   R = T
;   R = relhum(T,Q,P)
;   R = where(R.gt.100.0, 100.0, R)

  print("calculate near surface variables")
  ; Calculate near surface variables (do this instead of take from files do to greater availability of 3d)
        ; linearly extrapolate T2 in log(P) from 2 lowest hybrid levels)
        ; Assume RH at 2 m (R2) is same as RH at lowest hybrid level
        ; calculate Q2 from R2 and T2
        ; assume U10 and V10 follow a power law for a neutrally stable atmosphere and
                ;extrapolate them from the lowest hybrid level. Alpha = 0.143
                ;Hsu, S.A., et al, 1994,J. Appl. Meteor., Vol. 33, pp. 757-765
;   T2 = PS
;   T2 = T(:,1,:,:)-(T(:,1,:,:)-T(:,0,:,:))*((log(PS)-log(P(:,1,:,:)))/(log(P(:,0,:,:))-log(P(:,1,:,:))))
;   U10 = doubletofloat(U(:,0,:,:)*((10./(Z(:,0,:,:)-conform(PS,ZSFC,(/1,2/))))^0.145))
;   V10 = doubletofloat(V(:,0,:,:)*((10./(Z(:,0,:,:)-conform(PS,ZSFC,(/1,2/))))^0.145))

  R2 = R(:,0,:,:)
  T2  = TSKIN
  U10 = U(:,0,:,:)
  V10 = V(:,0,:,:)


;************************************************
; define arguments required by int2p
;************************************************
; type of interpolation: 1 = linear, 2 = log (-2 = log with extrapolation)
   interp = -2


;dimension of pressure levels
   pdim = 0


; create an array of desired pressure levels:
; pnew = (/ 1000.0, 975.0, 950.0, 925.0, 900.0, 850.0, 800.0, 750.0, 700.0, 650.0, 600.0, 550.0, 500.0, 450.0, 400.0, 350.0, 300.0, 250.0, 200.0, 150.0, 100.0, 70.0, 50.0, 30.0, 20.0, 10.0 /)

; pnew = (/ 1000.0, 975.0, 950.0, 925.0, 900.0, 850.0, 800.0, 750.0, 700.0, 650.0, 600.0, 550.0, 500.0, 450.0, 400.0, 350.0, 300.0, 250.0, 200.0, 150.0, 100.0, 70.0, 50.0 /)
; pnew = (/ 1000.0, 975.0, 950.0, 925.0, 900.0, 875.0, 850.0, 825.0, 800.0, 775.0, 750.0, 700.0, 650.0, 600.0, 550.0, 500.0, 450.0, 400.0, 350.0, 300.0, 250.0, 225.0, 200.0, 175.0, 150.0, 125.0, 100.0, 70.0, 50.0 /)
 pnew = (/ 1000.0, 975.0, 950.0, 925.0, 900.0, 875.0, 850.0, 825.0, 800.0, 775.0, 750.0, 700.0, 650.0, 600.0, 550.0, 500.0, 450.0, 400.0, 350.0, 300.0, 250.0, 225.0, 200.0, 175.0, 150.0, 125.0, 100.0, 70.0, 50.0, 30.0, 20.0, 10.0, 7.0, 5.0, 3.0, 2.0, 1.0/)





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;    WRITE OUT DATA TO WRF INTERMEDIATE FORMAT (CALL FORTRAN SUBROUTINE VIA WRAPIT77)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
     print("write out data to WRF intermediate files")

;      set the format to use for the date
       date_format = "%Y-%N-%D_%H:00:0000000"                   ;24 chars exact for binary file
       date_format2= "%Y-%N-%D_%H"                              ;for filename

;      Note that these are already preset for the regridded lat/lon grid the WRITE_INT subroutine (write_integer.f90)
;      Therefore if you adapt this code for some other type of atmospheric input you'll want to check these
;      IFV = 5
;      XFCST=0.0
;      MAP_SOURCE="REGRIDDED 1.0 x 1.00            "            ;32 chars exact
;      NX=136
;      NY=61
;      IPROJ=0
;      STARTLOC="SWCORNER"                                      ;8 chars exact
;      STARTLAT= 5.5
;      STARTLON= -170.5
;      DELTALAT=1.0
;      DELTALON=1.0
;      IS_WIND_EARTH_REL = new(1,logical)
;      IS_WIND_EARTH_REL = False
;      EARTH_RADIUS = 6367470. * .001

       FIELD_T="TT       "                                      ; 9 chars exact
       UNITS_T="K                        "                      ; 25 chars exact
       DESC_T="Temperature                                   "    ; 46 chars exact

       FIELD_U="UU       "                                      ; 9 chars exact
       UNITS_U="m s-1                    "                      ; 25 chars exact
       DESC_U="Zonal Wind Speed                              "    ; 46 chars exact

       FIELD_V="VV       "                                      ; 9 chars exact
       UNITS_V="m s-1                    "                      ; 25 chars exact
       DESC_V="Meridional Wind Speed                         "    ; 46 chars exact

       FIELD_Q="SPECHUMD "                                      ; 9 chars exact
       UNITS_Q="kg kg-1                  "                      ; 25 chars exact
       DESC_Q="Specific Humidity                             "    ; 46 chars exact

       FIELD_R="RH       "                                      ; 9 chars exact
       UNITS_R="%                        "                      ; 25 chars exact
       DESC_R="Relative Humidity                             "    ; 46 chars exact

       FIELD_Z="GHT      "                                      ; 9 chars exact
       UNITS_Z="m                        "                      ; 25 chars exact
       DESC_Z="Geopotential Height                           "    ; 46 chars exact

       FIELD_SLP="PMSL     "                                    ; 9 chars exact
       UNITS_SLP="Pa                       "                    ; 25 chars exact
       DESC_SLP="Sea level pressure                            "    ; 46 chars exact
       XLVL_SLP = 201300.

       FIELD_PS="PSFC     "                                     ; 9 chars exact
       UNITS_PS="Pa                       "                     ; 25 chars exact
       DESC_PS="Surface pressure                              "    ; 46 chars exact
       XLVL_PS = 200100.

       FIELD_U10="UU       "                                    ; 9 chars exact
       UNITS_U10="m s-1                    "                    ; 25 chars exact
       DESC_U10="10 m Zonal Wind Speed                         "    ; 46 chars exact
       XLVL_U10 = 200100.

       FIELD_V10="VV       "                                    ; 9 chars exact
       UNITS_V10="m s-1                    "                    ; 25 chars exact
       DESC_V10="10 m Meridional Wind Speed                    "    ; 46 chars exact
       XLVL_V10 = 200100.

       FIELD_T2="TT       "                                     ; 9 chars exact
       UNITS_T2="K                        "                     ; 25 chars exact
       DESC_T2="2 m Temperature                               "    ; 46 chars exact
       XLVL_T2 = 200100.

       FIELD_Q2="SPECHUMD "                                     ; 9 chars exact
       UNITS_Q2="kg kg-1                  "                     ; 25 chars exact
       DESC_Q2="2 m Specific Humidity                         "    ; 46 chars exact
       XLVL_Q2 = 200100.

       FIELD_R2="RH       "                                     ; 9 chars exact
       UNITS_R2="%                        "                     ; 25 chars exact
       DESC_R2="2 m Relative Humidity                         "    ; 46 chars exact
       XLVL_R2 = 200100.

       FIELD_SNOWW6="SNOW     "                                 ; 9 chars exact
       UNITS_SNOWW6="kg m-2                   "                 ; 25 chars exact
       DESC_SNOWW6="Water Equivalent of Accum Snow Depth          "    ; 46 chars exact
       XLVL_SNOWW6 = 200100.

       FIELD_TSKIN6="SKINTEMP "                                 ; 9 chars exact
       UNITS_TSKIN6="K                        "                 ; 25 chars exact
       DESC_TSKIN6="Skin Temperature                              "    ; 46 chars exact
       XLVL_TSKIN6 = 200100.

       FIELD_TAVGSFC6="TAVGSFC  "                                       ; 9 chars exact
       UNITS_TAVGSFC6="K                        "                       ; 25 chars exact
       DESC_TAVGSFC6="Daily mean of surface air temperature         "    ; 46 chars exact
       XLVL_TAVGSFC6 = 200100.

       FIELD_SST6="SST      "                                   ; 9 chars exact
       UNITS_SST6="K                        "                   ; 25 chars exact
       DESC_SST6="Sea Surface Temperature                       "    ; 46 chars exact
       XLVL_SST6 = 200100.

       FIELD_ICE6="SEAICE   "                                   ; 9 chars exact
       UNITS_ICE6="fraction                 "                   ; 25 chars exact
       DESC_ICE6="Sea-Ice-Fraction                              "    ; 46 chars exact
       XLVL_ICE6 = 200100.

       FIELD_TSOIL1_6="ST000010 "                                       ; 9 chars exact
       UNITS_TSOIL1_6="K                        "                       ; 25 chars exact
       DESC_TSOIL1_6="Soil Temperature 0-10 cm  layer               "    ; 46 chars exact
       XLVL_TSOIL1_6 = 200100.

       FIELD_TSOIL2_6="ST010040 "                                       ; 9 chars exact
       UNITS_TSOIL2_6="K                        "                       ; 25 chars exact
       DESC_TSOIL2_6="Soil Temperature 10-40 cm  layer              "    ; 46 chars exact
       XLVL_TSOIL2_6 = 200100.

       FIELD_TSOIL3_6="ST040100 "                                       ; 9 chars exact
       UNITS_TSOIL3_6="K                        "                       ; 25 chars exact
       DESC_TSOIL3_6="Soil Temperature 40-100 cm  layer             "    ; 46 chars exact
       XLVL_TSOIL3_6 = 200100.

       FIELD_TSOIL4_6="ST100200 "                                       ; 9 chars exact
       DESC_TSOIL4_6="Soil Temperature 100-200 cm  layer            "    ; 46 chars exact
       XLVL_TSOIL4_6 = 200100.

       FIELD_MSOIL1_6="SM000010 "                                       ; 9 chars exact
       UNITS_MSOIL1_6="fraction                 "                       ; 25 chars exact
       DESC_MSOIL1_6="Soil Moisture    0-10 cm  layer               "    ; 46 chars exact
       XLVL_MSOIL1_6 = 200100.

       FIELD_MSOIL2_6="SM010040 "                                       ; 9 chars exact
       UNITS_MSOIL2_6="fraction                 "                       ; 25 chars exact
       DESC_MSOIL2_6="Soil Moisture    10-40 cm  layer              "    ; 46 chars exact
       XLVL_MSOIL2_6 = 200100.

       FIELD_MSOIL3_6="SM040100 "                                       ; 9 chars exact
       UNITS_MSOIL3_6="fraction                 "                       ; 25 chars exact
       DESC_MSOIL3_6="Soil Moisture    40-100 cm  layer             "    ; 46 chars exact
       XLVL_MSOIL3_6 = 200100.

       FIELD_MSOIL4_6="SM100200 "                                       ; 9 chars exact
       UNITS_MSOIL4_6="fraction                 "                       ; 25 chars exact
       DESC_MSOIL4_6="Soil Moisture    100-200 cm  layer            "    ; 46 chars exact
       XLVL_MSOIL4_6 = 200100.

       FIELD_LMASK="LANDSEA "                                   ; 9 chars exact
       UNITS_LMASK="proprtn                  "                  ; 25 chars exact
       DESC_LMASK="Land/Sea Flag; 0=Ocean; 1=Land                "    ; 46 chars exact
       XLVL_LMASK = 200100.

       FIELD_ZSFC="SOILHGT "                                    ; 9 chars exact
       UNITS_ZSFC="m                        "                   ; 25 chars exact
       DESC_ZSFC="Terrain Elevation                             "    ; 46 chars exact
       XLVL_ZSFC = 200100.

;  for each time
  do TIM = 0,nmonths-1
; do TIM = 0,0

;       calculate 3-d variables on pressure levels (need to do this here because ncl doesn't like multiple times)
;       print("extrapolate variables to pressure levels")
        print("interpolate or extrapolate variables to pressure levels")
;       varflg = 1
;       TonP = vinth2p_ecmwf(T(TIM,::-1,:,:),hyam(::-1),hybm(::-1),pnew,PS(TIM,:,:),interp,P0,1,extrap,varflg,TBOT(TIM,:,:),PHIS)
;       varflg = -1
;       ZonP = vinth2p_ecmwf(Z(TIM,::-1,:,:),hyam(::-1),hybm(::-1),pnew,PS(TIM,:,:),interp,P0,1,extrap,varflg,TBOT(TIM,:,:),PHIS)
;       varflg = 0
;       UonP = vinth2p_ecmwf(U(TIM,::-1,:,:),hyam(::-1),hybm(::-1),pnew,PS(TIM,:,:),interp,P0,1,extrap,varflg,TBOT(TIM,:,:),PHIS)
;       VonP = vinth2p_ecmwf(V(TIM,::-1,:,:),hyam(::-1),hybm(::-1),pnew,PS(TIM,:,:),interp,P0,1,extrap,varflg,TBOT(TIM,:,:),PHIS)
;       RonP = vinth2p_ecmwf(R(TIM,::-1,:,:),hyam(::-1),hybm(::-1),pnew,PS(TIM,:,:),interp,P0,1,extrap,varflg,TBOT(TIM,:,:),PHIS)
;        RonP = where(RonP.gt.100.0, 100.0, RonP)
;        RonP = where(RonP.lt.0.0, 0.0, RonP)

        ; calcualte slp using ecmwf formulation (no 6-hourly or 3-hourly slp output is otherwise available)
;        SLP = doubletofloat(pslec(TBOT(TIM,:,:),PHIS,PS(TIM,:,:),P(TIM,0,:,:)))

        TonP = int2p_n_Wrap(PLEV,T(TIM,:,:,:),pnew,interp,0)
        ZonP = int2p_n_Wrap(PLEV,Z(TIM,:,:,:),pnew,interp,0)
        UonP = int2p_n_Wrap(PLEV,U(TIM,:,:,:),pnew,interp,0)
        VonP = int2p_n_Wrap(PLEV,V(TIM,:,:,:),pnew,interp,0)
        QonP = int2p_n_Wrap(PLEV,Q(TIM,:,:,:),pnew,interp,0)
        
        RonP = int2p_n_Wrap(PLEV,R(TIM,:,:,:),pnew,interp,0)
        RonP = where(RonP.gt.100.0, 100.0, RonP)
        RonP = where(RonP.lt.0.0, 0.0, RonP)



        SLP = PS(TIM,:,:)

;        SLP = where(ismissing(SLP),100000.,SLP)

;       set dates for file input and filename
        HDATE = cd_string(time(TIM), date_format)
        print("HDATE= " + HDATE)
        OFILE = model_name+"_"+CASE+":" + cd_string(time(TIM), date_format2)
        yyyy = cd_string(time(TIM),"%Y")

;    write out the constants if the time step is #1
;   if (TIM .eq. 0) then
;    system ("rm wrfintout.bin") ; just in case...remove old generic intermediate file first
;    WRITEINT::write_intermediate(HDATE,FIELD_LMASK,UNITS_LMASK,DESC_LMASK,XLVL_LMASK,LMASK(:,:)) ; (lat,lon)
;    WRITEINT::write_intermediate(HDATE,FIELD_ZSFC,UNITS_ZSFC,DESC_ZSFC,XLVL_ZSFC,doubletofloat(ZSFC(:,:))) ; (lat,lon)
;    system ("mv wrfintout.bin ./OUTPUT/CCSM_CONSTANTS_FILE") ; rename
;   end if

;       remove the generically-named intermediate file if it exists, as well as the specifically named one
        system ("rm wrfintout.bin")
        system ("rm " + OFILE)
        system ("mkdir -p /glade/scratch/anewman/cmip5/wps/" + model_name + "/" + yyyy)
        system ("rm /glade/scratch/anewman/cmip5/wps/" + model_name + "/" + yyyy + "/" + OFILE)

;   write any non-level variables (including treament of soil temp/moisture profiles as single levels each)

     WRITEINT::write_intermediate(HDATE,FIELD_LMASK,UNITS_LMASK,DESC_LMASK,XLVL_LMASK,LMASK(:,:)) ; (lat,lon)
     WRITEINT::write_intermediate(HDATE,FIELD_ZSFC,UNITS_ZSFC,DESC_ZSFC,XLVL_ZSFC,doubletofloat(ZSFC(:,:))) ; (lat,lon)
     WRITEINT::write_intermediate(HDATE,FIELD_TSKIN6,UNITS_TSKIN6,DESC_TSKIN6,XLVL_TSKIN6,TSKIN6(TIM,:,:)) ; (tim,lat,lon)
     WRITEINT::write_intermediate(HDATE,FIELD_TAVGSFC6,UNITS_TAVGSFC6,DESC_TAVGSFC6,XLVL_TAVGSFC6,TAVGSFC6(TIM,:,:)) ; (tim,lat,lon)
     WRITEINT::write_intermediate(HDATE,FIELD_SST6,UNITS_SST6,DESC_SST6,XLVL_SST6,SST6(TIM,:,:)) ; (tim,lat,lon)
     WRITEINT::write_intermediate(HDATE,FIELD_ICE6,UNITS_ICE6,DESC_ICE6,XLVL_ICE6,ICE6(TIM,:,:)) ; (tim,lat,lon)
     WRITEINT::write_intermediate(HDATE,FIELD_SNOWW6,UNITS_SNOWW6,DESC_SNOWW6,XLVL_SNOWW6,SNOWW6(TIM,:,:)) ; (tim,lat,lon)
     WRITEINT::write_intermediate(HDATE,FIELD_TSOIL1_6,UNITS_TSOIL1_6,DESC_TSOIL1_6,XLVL_TSOIL1_6,TSOIL1_6(TIM,:,:)) ; (tim,lat,lon)
     WRITEINT::write_intermediate(HDATE,FIELD_TSOIL2_6,UNITS_TSOIL2_6,DESC_TSOIL2_6,XLVL_TSOIL2_6,TSOIL2_6(TIM,:,:)) ; (tim,lat,lon)
     WRITEINT::write_intermediate(HDATE,FIELD_TSOIL3_6,UNITS_TSOIL3_6,DESC_TSOIL3_6,XLVL_TSOIL3_6,TSOIL3_6(TIM,:,:)) ; (tim,lat,lon)
     WRITEINT::write_intermediate(HDATE,FIELD_TSOIL4_6,UNITS_TSOIL4_6,DESC_TSOIL4_6,XLVL_TSOIL4_6,TSOIL4_6(TIM,:,:)) ; (tim,lat,lon)
     WRITEINT::write_intermediate(HDATE,FIELD_MSOIL1_6,UNITS_MSOIL1_6,DESC_MSOIL1_6,XLVL_MSOIL1_6,MSOIL1_6(TIM,:,:)) ; (tim,lat,lon)
     WRITEINT::write_intermediate(HDATE,FIELD_MSOIL2_6,UNITS_MSOIL2_6,DESC_MSOIL2_6,XLVL_MSOIL2_6,MSOIL2_6(TIM,:,:)) ; (tim,lat,lon)
     WRITEINT::write_intermediate(HDATE,FIELD_MSOIL3_6,UNITS_MSOIL3_6,DESC_MSOIL3_6,XLVL_MSOIL3_6,MSOIL3_6(TIM,:,:)) ; (tim,lat,lon)
     WRITEINT::write_intermediate(HDATE,FIELD_MSOIL4_6,UNITS_MSOIL4_6,DESC_MSOIL4_6,XLVL_MSOIL4_6,MSOIL4_6(TIM,:,:)) ; (tim,lat,lon)

     WRITEINT::write_intermediate(HDATE,FIELD_SLP,UNITS_SLP,DESC_SLP,XLVL_SLP,SLP(:,:)) ; (lat,lon)
     WRITEINT::write_intermediate(HDATE,FIELD_PS,UNITS_PS,DESC_PS,XLVL_PS,PS(TIM,:,:))  ; (tim,lat,lon)
     WRITEINT::write_intermediate(HDATE,FIELD_U10,UNITS_U10,DESC_U10,XLVL_U10,U10(TIM,:,:))     ; (tim,lat,lon)
     WRITEINT::write_intermediate(HDATE,FIELD_V10,UNITS_V10,DESC_V10,XLVL_V10,V10(TIM,:,:))     ; (tim,lat,lon)
     WRITEINT::write_intermediate(HDATE,FIELD_T2,UNITS_T2,DESC_T2,XLVL_T2,T2(TIM,:,:))  ; (tim,lat,lon)
;    WRITEINT::write_intermediate(HDATE,FIELD_Q2,UNITS_Q2,DESC_Q2,XLVL_Q2,Q2(TIM,:,:))  ; (tim,lat,lon)
     WRITEINT::write_intermediate(HDATE,FIELD_R2,UNITS_R2,DESC_R2,XLVL_R2,R2(TIM,:,:))  ; (tim,lat,lon)
;   for each level
   do LEV=0,dimsizes(pnew)-1
  ;do LEV=0,0

     XLVL=pnew(LEV)*100.
     
     WRITEINT::write_intermediate(HDATE,FIELD_U,UNITS_U,DESC_U,XLVL,UonP(LEV,:,:))
     WRITEINT::write_intermediate(HDATE,FIELD_V,UNITS_V,DESC_V,XLVL,VonP(LEV,:,:))
     WRITEINT::write_intermediate(HDATE,FIELD_T,UNITS_T,DESC_T,XLVL,TonP(LEV,:,:))
;    WRITEINT::write_intermediate(HDATE,FIELD_Q,UNITS_Q,DESC_Q,XLVL,QonP(LEV,:,:))
     WRITEINT::write_intermediate(HDATE,FIELD_R,UNITS_R,DESC_R,XLVL,RonP(LEV,:,:))
;    print("MINR on LEV "+XLVL+" = "+min(RonP(LEV,:,:)))
;    print("MAXR on LEV "+XLVL+" = "+max(RonP(LEV,:,:)))
     WRITEINT::write_intermediate(HDATE,FIELD_Z,UNITS_Z,DESC_Z,XLVL,ZonP(LEV,:,:))

     ; Loop back and read next level
       delete(XLVL)
   end do

     ; change generic filename to that for specific date
;        system ("mv wrfintout.bin ./OUTPUT/" +yyyy+ "/" + OFILE)
        system ("mv wrfintout.bin /glade/scratch/anewman/cmip5/wps/" + model_name + "/" + yyyy + "/" + OFILE)

     ; Loop back and read next time
     delete(HDATE)
     delete(OFILE)
  end do

end
