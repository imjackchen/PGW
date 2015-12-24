load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"


begin

;----------------------------------------------------------------------------------
; Path to input files
;----------------------------------------------------------------------------------

  ; Years
   iyr = 1979.
   nyrs = 1

 ; iyr = fspan(1980,2009,30)
 ; nyrs = 30

  ; For 1979 only
   imon=(/"06","07","08","09","10","11","12","01"/)
   iday=(/30,31,31,31,30,31,31,1/)
   
  ; For any other year    ( leap years are : 1980, 1984, 1988, 1992, 1996, 2000, 2004, 2008 )
  ;imon=(/"12","01","02","03","04","05","06","07","08","09","10","11","12","01"/)
  ;iday=(/31,30,31,31,29,31,30,1/)

   idate=(/"01","02","03","04","05","06","07","08","09","10","11","12","13","14","15","16",\
           "17","18","19","20","21","22","23","24","25","26","27","28","29","30","31"/)
   iutc=(/"00","06","12","18"/)

  ; number of month
   itmn = 7
  ; number of forecast time
   itim = 1
  ;itim = 4

;----------------------------------------------------------------------------------
; Path to input files
;----------------------------------------------------------------------------------

 dir1 = "/gpfs/ptmp/kyoko/gochis/WPS_PGW/"
 dir2 = "/gpfs/ptmp/kyoko/gochis/WPS_mean_CCSM_century/"
 dir3 = "/gpfs/ptmp/kyoko/gochis/WPS_mean_CCSM_A2/"
 dir4 = "/gpfs/ptmp/kyoko/gochis/WPS_CCSM_ANNUAL_MEAN/"

;----------------------------------------------------------------------------------
; Filenames for the annunal mean soil temperature
;----------------------------------------------------------------------------------
 X_1995=addfile(dir4+"met_em.d01.2005-12-31_18:00:00.nc","r")
 X_2045=addfile(dir4+"met_em.d01.2055-12-31_18:00:00.nc","r")

;----------------------------------------------------------------------------------
; Compute perturbation and generate PGW files.
;----------------------------------------------------------------------------------

 tdays=0.
 days =0.
 alpha=0.
 beta =0.
 
 do iy=0,nyrs-1   ; loop years

    do im=1,1     ; loop months
      ;do im=1,itmn
       print(im)

       do id=0,iday(im)-1  ; loop days
          month = stringtoint(imon(im))
          if (iyr.eq.1979 .and. month.eq.7 ) then
             id = iday(im)-1
          end if
          print(id)

          do ih=0,itim-1   ; loop model time
             print(ih)

             tm=imon(im)     ; this (current) month
             lm=imon(im-1)   ; last month
             nm=imon(im+1)   ; next month

             if( im.lt.7) then
                year_str = sprintf("%4.0f",iyr(iy))
                filename = dir1 + "met_em.d01." + year_str + "-" + tm + "-" + idate(id) + "_" + iutc(ih) + ":00:00.nc"
             else
                year_str = sprintf("%4.0f",iyr(iy)+1)
                filename = dir1 + "met_em.d01." + year_str + "-" + tm + "-" + idate(id) + "_" + iutc(ih) + ":00:00.nc"
             end if

             print(filename)
             X_narr=addfile(filename,"w")

             if (stringtoint(imon(im)).ne.2) then
                ndays_0 = sprintf("%2.0f", int2flt(iday(im)) )
                ndays_1 = sprintf("%2.0f", int2flt(iday(im-1)))
                ndays_2 = sprintf("%2.0f", int2flt(iday(im+1)))
                X_p_tm=addfile(dir2+"met_em.d01.2005-"+tm+"-" + ndays_0 + "_18:00:00.nc","r")
                X_p_lm=addfile(dir2+"met_em.d01.2005-"+lm+"-" + ndays_1 + "_18:00:00.nc","r")
                X_p_nm=addfile(dir2+"met_em.d01.2005-"+nm+"-" + ndays_2 + "_18:00:00.nc","r")
                X_f_tm=addfile(dir3+"met_em.d01.2055-"+tm+"-" + ndays_0 + "_18:00:00.nc","r")
                X_f_lm=addfile(dir3+"met_em.d01.2055-"+lm+"-" + ndays_1 + "_18:00:00.nc","r")
                X_f_nm=addfile(dir3+"met_em.d01.2055-"+nm+"-" + ndays_2 + "_18:00:00.nc","r")
             else
                X_p_tm=addfile(dir2+"met_em.d01.2005-"+tm+"-28_18:00:00.nc","r")
                X_p_lm=addfile(dir2+"met_em.d01.2005-"+lm+"-28_18:00:00.nc","r")
                X_p_nm=addfile(dir2+"met_em.d01.2005-"+nm+"-28_18:00:00.nc","r")
                X_f_tm=addfile(dir3+"met_em.d01.2055-"+tm+"-28_18:00:00.nc","r")
                X_f_lm=addfile(dir3+"met_em.d01.2055-"+lm+"-28_18:00:00.nc","r")
                X_f_nm=addfile(dir3+"met_em.d01.2055-"+nm+"-28_18:00:00.nc","r")
             end if

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; UU field

               u_narr = X_narr->UU
               
               u_p_tm = X_p_tm->UU
               u_p_lm = X_p_lm->UU
               u_p_nm = X_p_nm->UU

               u_f_tm = X_f_tm->UU
               u_f_lm = X_f_lm->UU
               u_f_nm = X_f_nm->UU

               if(id.lt.15) then
                tdays = int2flt(iday(im-1))     ; from 0000 UTC 16th of last month to 0000 UTC 16th of this month
                days  = int2flt(iday(im-1))-15.+int2flt(id)+3.*int2flt(ih)/24.
                alpha = (tdays-days)/tdays
                beta  = 1.-alpha
                u_new = u_narr + alpha * (u_f_lm - u_p_lm) + beta * (u_f_tm - u_p_tm)
               else
                tdays = int2flt(iday(im))       ; from 0000 UTC 16th of current month to 0000 UTC 16th of next month
                days  = int2flt(id)-15.+3.*int2flt(ih)/24.
                alpha = (tdays-days)/tdays
                beta  = 1.-alpha
                u_new = u_narr + alpha * (u_f_tm - u_p_tm) + beta * (u_f_nm - u_p_nm)
               end if

               X_narr->UU=u_new

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; VV field

               v_narr = X_narr->VV

               v_p_tm = X_p_tm->VV
               v_p_lm = X_p_lm->VV
               v_p_nm = X_p_nm->VV

               v_f_tm = X_f_tm->VV
               v_f_lm = X_f_lm->VV
               v_f_nm = X_f_nm->VV

               if(id.lt.15) then
                tdays = int2flt(iday(im-1))     ; from 0000 UTC 16th of last month to 0000 UTC 16th of this month
                days  = int2flt(iday(im-1))-15.+int2flt(id)+3.*int2flt(ih)/24.
                alpha = (tdays-days)/tdays
                beta  = 1.-alpha
                v_new = v_narr + alpha * (v_f_lm - v_p_lm) + beta * (v_f_tm - v_p_tm)
               else
                tdays = int2flt(iday(im))       ; from 0000 UTC 16th of current month to 0000 UTC 16th of next month
                days  = int2flt(id)-15.+3.*int2flt(ih)/24.
                alpha = (tdays-days)/tdays
                beta  = 1.-alpha
                v_new = v_narr + alpha * (v_f_tm - v_p_tm) + beta * (v_f_nm - v_p_nm)
               end if

               X_narr->VV=v_new
               
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; TT field

               t_narr = X_narr->TT

               t_p_tm = X_p_tm->TT
               t_p_lm = X_p_lm->TT
               t_p_nm = X_p_nm->TT

               t_f_tm = X_f_tm->TT
               t_f_lm = X_f_lm->TT
               t_f_nm = X_f_nm->TT

               if(id.lt.15) then
                tdays = int2flt(iday(im-1))     ; from 0000 UTC 16th of last month to 0000 UTC 16th of this month
                days  = int2flt(iday(im-1))-15.+int2flt(id)+3.*int2flt(ih)/24.
                alpha = (tdays-days)/tdays
                beta  = 1.-alpha
                t_new = t_narr + alpha * (t_f_lm - t_p_lm) + beta * (t_f_tm - t_p_tm)
               else
                tdays = int2flt(iday(im))       ; from 0000 UTC 16th of current month to 0000 UTC 16th of next month
                days  = int2flt(id)-15.+3.*int2flt(ih)/24.
                alpha = (tdays-days)/tdays
                beta  = 1.-alpha
                t_new = t_narr + alpha * (t_f_tm - t_p_tm) + beta * (t_f_nm - t_p_nm)
               end if

               X_narr->TT=t_new

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; RH field

               rh_narr = X_narr->RH

               rh_p_tm = X_p_tm->RH
               rh_p_lm = X_p_lm->RH
               rh_p_nm = X_p_nm->RH

               rh_f_tm = X_f_tm->RH
               rh_f_lm = X_f_lm->RH
               rh_f_nm = X_f_nm->RH

               if(id.lt.15) then
                tdays = int2flt(iday(im-1))     ; from 0000 UTC 16th of last month to 0000 UTC 16th of this month
                days  = int2flt(iday(im-1))-15.+int2flt(id)+3.*int2flt(ih)/24.
                alpha = (tdays-days)/tdays
                beta  = 1.-alpha
                rh_new = rh_narr + alpha * (rh_f_lm - rh_p_lm) + beta * (rh_f_tm - rh_p_tm)
               else
                tdays = int2flt(iday(im))       ; from 0000 UTC 16th of current month to 0000 UTC 16th of next month
                days  = int2flt(id)-15.+3.*int2flt(ih)/24.
                alpha = (tdays-days)/tdays
                beta  = 1.-alpha
                rh_new = rh_narr + alpha * (rh_f_tm - rh_p_tm) + beta * (rh_f_nm - rh_p_nm)
               end if

               X_narr->RH=rh_new

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; GHT field

               ght_narr = X_narr->GHT

               ght_p_tm = X_p_tm->GHT
               ght_p_lm = X_p_lm->GHT
               ght_p_nm = X_p_nm->GHT

               ght_f_tm = X_f_tm->GHT
               ght_f_lm = X_f_lm->GHT
               ght_f_nm = X_f_nm->GHT

               if(id.lt.15) then
                tdays = int2flt(iday(im-1))     ; from 0000 UTC 16th of last month to 0000 UTC 16th of this month
                days  = int2flt(iday(im-1))-15.+int2flt(id)+3.*int2flt(ih)/24.
                alpha = (tdays-days)/tdays
                beta  = 1.-alpha
                ght_new = ght_narr + alpha * (ght_f_lm - ght_p_lm) + beta * (ght_f_tm - ght_p_tm)
               else
                tdays = int2flt(iday(im))       ; from 0000 UTC 16th of current month to 0000 UTC 16th of next month
                days  = int2flt(id)-15.+3.*int2flt(ih)/24.
                alpha = (tdays-days)/tdays
                beta  = 1.-alpha
                ght_new = ght_narr + alpha * (ght_f_tm - ght_p_tm) + beta * (ght_f_nm - ght_p_nm)
               end if

               X_narr->GHT=ght_new

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; SKINTEMP field

               skintemp_narr = X_narr->SKINTEMP

               sst_p_tm = X_p_tm->SST
               sst_p_lm = X_p_lm->SST
               sst_p_nm = X_p_nm->SST

               sst_f_tm = X_f_tm->SST
               sst_f_lm = X_f_lm->SST
               sst_f_nm = X_f_nm->SST

               if(id.lt.15) then
                tdays = int2flt(iday(im-1))     ; from 0000 UTC 16th of last month to 0000 UTC 16th of this month
                days  = int2flt(iday(im-1))-15.+int2flt(id)+3.*int2flt(ih)/24.
                alpha = (tdays-days)/tdays
                beta  = 1.-alpha
                skintemp_new = skintemp_narr + alpha * (sst_f_lm - sst_p_lm) + beta * (sst_f_tm - sst_p_tm)
               else
                tdays = int2flt(iday(im))       ; from 0000 UTC 16th of current month to 0000 UTC 16th of next month
                days  = int2flt(id)-15.+3.*int2flt(ih)/24.
                alpha = (tdays-days)/tdays
                beta  = 1.-alpha
                skintemp_new = skintemp_narr + alpha * (sst_f_tm - sst_p_tm) + beta * (sst_f_nm - sst_p_nm)
               end if

               X_narr->SKINTEMP=skintemp_new

               if (im.eq.1 .and. id.eq.0 .and. ih.eq.0) then
                  print(" im, id, ih = "+im+", "+id+", "+ih)

                  t1_p_tm = X_p_tm->TT(:,0,:,:)
                  t1_p_lm = X_p_lm->TT(:,0,:,:)

                  t1_f_tm = X_f_tm->TT(:,0,:,:)
                  t1_f_lm = X_f_lm->TT(:,0,:,:)

                  a_temp_p = X_1995->TT(:,0,:,:)
                  a_temp_f = X_2045->TT(:,0,:,:)

               ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
               ; ST000010 field

                  st000010_narr = X_narr->ST000010

                   tdays = int2flt(iday(im-1))     ; from 0000 UTC 16th of last month to 0000 UTC 16th of this month
                   days  = int2flt(iday(im-1))-15.+int2flt(id)+3.*int2flt(ih)/24.
                   alpha = (tdays-days)/tdays
                   beta  = 1.-alpha
                   st000010_new = st000010_narr + alpha * (t1_f_lm - t1_p_lm) + beta * (t1_f_tm - t1_p_tm)

                  X_narr->ST000010=st000010_new

               ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
               ; ST010040 field

                  st010040_narr = X_narr->ST010040

                   tdays = int2flt(iday(im-1))     ; from 0000 UTC 16th of last month to 0000 UTC 16th of this month
                   days  = int2flt(iday(im-1))-15.+int2flt(id)+3.*int2flt(ih)/24.
                   alpha = (tdays-days)/tdays
                   beta  = 1.-alpha
                   st010040_new = st010040_narr + alpha * (t1_f_lm - t1_p_lm) + beta * (t1_f_tm - t1_p_tm)

                  X_narr->ST010040=st010040_new

               ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
               ; ST040100 field

                  st040100_narr = X_narr->ST040100

                   tdays = int2flt(iday(im-1))     ; from 0000 UTC 16th of last month to 0000 UTC 16th of this month
                   days  = int2flt(iday(im-1))-15.+int2flt(id)+3.*int2flt(ih)/24.
                   alpha = (tdays-days)/tdays
                   beta  = 1.-alpha
                   st040100_new = st040100_narr + 2./3.*alpha * (t1_f_lm - t1_p_lm) + 2./3.*beta * (t1_f_tm - t1_p_tm) + 1./3. * (a_temp_f - a_temp_p)

                  X_narr->ST040100=st040100_new

               ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
               ; ST100200 field

                  st100200_narr = X_narr->ST100200

                   tdays = int2flt(iday(im-1))     ; from 0000 UTC 16th of last month to 0000 UTC 16th of this month
                   days  = int2flt(iday(im-1))-15.+int2flt(id)+3.*int2flt(ih)/24.
                   alpha = (tdays-days)/tdays
                   beta  = 1.-alpha
                   st100200_new = st100200_narr + 1./3.*alpha * (t1_f_lm - t1_p_lm) + 1./3.*beta * (t1_f_tm - t1_p_tm) + 2./3. * (a_temp_f - a_temp_p)

                  X_narr->ST100200=st100200_new

               ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
               ; SOILTEMP field

                  soiltemp_narr = X_narr->SOILTEMP

                  soiltemp_new = soiltemp_narr + (a_temp_f - a_temp_p)
                  
                  X_narr->SOILTEMP=soiltemp_new

               end if

          end do
       end do
    end do
 end do   ; loop through years

end
