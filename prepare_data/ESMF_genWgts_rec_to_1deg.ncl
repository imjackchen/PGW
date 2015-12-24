;----------------------------------------------------------------------
; ESMF_rec_to_1deg.ncl
;
;
;  Purpose :
;            This is an NCL/ESMF file for regridding from a rectilinear
;            grid to a 1 degree grid.
;
;            1) Read weight file, produced from ESMF_genWgts_rec_to_1deg.ncl
;            2) Generated regridded datasets 
;
;            Search for lines with ";;---Change (likely)" or ";;---Change (maybe)".
;            These are the lines you will likely or maybe have to change.
;
; Usage    : ncl 'ModelName="CCSM4"' 'InDir="/glade/scratch/chenl/CMIP5/CCSM4/"' \
;                'LatName="lat"' 'LonName="lon"' \
;                'FileType="cdf"' \
;                 ESMF_rec_to_1deg.ncl
;
;             FileType = "cdf"/"nc"/"grb1"/"grb2"
;
; liang chen 24 Dec. 2015
;            
;----------------------------------------------------------------------
; This example uses the ESMF application "ESMF_RegridWeightGen" to 
; generate the weights.
;
; For more information about ESMF:
;
;        http://www.earthsystemmodeling.org/
;
; This script uses built-in functions that are only available in 
; NCL V6.1.0-beta and later.
;
; For more information on ESMF_regrid, see: 
;    http://www.ncl.ucar.edu/Document/Functions/ESMF/ESMF_regrid.shtml
;----------------------------------------------------------------------
;----------------------------------------------------------------------
;----------------------------------------------------------------------
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin
;----------------------------------------------------------------------
; User specified fields
;----------------------------------------------------------------------

;---Output path
;    model_name=str_lower(ModelName)
    OutDir = "/glade/scratch/chenl/CMIP5/regridded/"+ModelName+"/"

;---Output (and input) files
    WGT_DIR     = "./ESMF_wgt_files/"
    srcGridName = WGT_DIR+"src_SCRIP_"+ModelName+".nc"
    dstGridName = WGT_DIR+"dst_SCRIP_latlon_1deg.nc"
    wgtFileName_tmp = WGT_DIR+ModelName+"2DST_weights_latlon_1deg"

;---Plot regridded field to check?  (yes = 1, no = 0)
    plot_opt = 0;

;----------------------------------------------------------------------
; Check if src and dst grid files exists
;----------------------------------------------------------------------
    exist = isfilepresent( srcGridName ) 
    if (.not.exist) then
       print( " ... srcGrid file does not exist : "+srcGridName )
       exit
    end if
    delete(exist)

    exist = isfilepresent( dstGridName ) 
    if (.not.exist) then
       print( " ... dstGrid file does not exist : "+dstGridName )
       exit
    end if
    delete(exist)

;----------------------------------------------------------------------
; List of input files
;----------------------------------------------------------------------

   if ( ModelName .eq. "ERA-Intrim-SFC-6hrly" ) then
       datfiles = systemfunc ("/bin/ls "+InDir+"ei.oper.an.*" )
   else if ( ModelName .eq. "ERA-Intrim-PLev-6hrly" ) then
       datfiles = systemfunc ("/bin/ls "+InDir+"ei.*"+FileType )
   else
      ;datfiles = systemfunc ("/bin/ls "+InDir+"*_"+frequency+"_*"+Experiment+"_*."+FileType)
       datfiles = systemfunc ("/bin/ls "+InDir+Var+"_"+frequency+"_*"+Experiment+"_*."+FileType)
   end if
   end if

   nFiles  = dimsizes( datfiles )
   print( datfiles )
   system("mkdir "+OutDir)


  ;do ifil = 0,0
   do ifil = 0,nFiles-1

   ;----------------------------------------------------------------------
   ; Open input file ; Write output
   ; Never overwrite the original file!!
   ;----------------------------------------------------------------------
       FileName = datfiles(ifil)

       if ( FileType .eq. "grb2" .or. FileType .eq. "grb1" ) then
          srcFile = addfile( FileName+"."+FileType, "r")
       else
          srcFile = addfile( FileName, "r")
       end if
   
       strs        = str_split( FileName , "/")
       nLen        = dimsizes( strs )
       OutFileName = OutDir+strs(nLen-1)

       if ( FileType .eq. "grb1" .or. FileType .eq. "grb2" )
          OutFileName = OutFileName+".nc"
         ;OutFileName = str_sub_str( OutFileName , FileType , "nc")
       end if

       print( " ... Output filename : "+OutFileName )
       if ( isfilepresent( OutFileName)) then
          system("/bin/rm "+OutFileName)
       end if
       delete( nLen )
       delete( strs )
       dstFile = addfile( OutFileName, "c")


   ;----------------------------------------------------------------------
   ; Get variable names, lat, and lon.  Corners for conserve method.
   ;----------------------------------------------------------------------
   
       src_lat = srcFile->$LatName$ 
       src_lon = srcFile->$LonName$

       src_corner_lat = srcFile->$LatCornerName$ 
       src_corner_lon = srcFile->$LonCornerName$

       vNames = getfilevarnames (srcFile) ; get names of all variables on file
       nNames = dimsizes (vNames)         ; number of fields
   
       print( vNames )

   ;----------------------------------------------------------------------
   ; Options for remapping
   ;----------------------------------------------------------------------

       Opt                  = True
       Opt@SkipSrcGrid      = True
       Opt@SkipDstGrid      = True
       Opt@SkipWgtGen       = False
       Opt@SrcFileName      = srcGridName   ; source file name
       Opt@DstFileName      = dstGridName   ; destination file name
       Opt@ForceOverwrite   = False
   
       Opt@SrcRegional      = False
       Opt@DstRegional      = True
       Opt@SrcGridLat       = src_lat
       Opt@SrcGridLon       = src_lon
   
      ;Opt@DstGridType      = "1x1"              ; Destination grid
       Opt@DstGridType      = "rectilinear"              ; Destination grid
      ;Opt@DstTitle         = "1-degree Resolution"
      ;Opt@LLCorner       = (/ 5.5d, -170.5d/)
      ;Opt@URCorner       = (/ 65.5d, -35.5d/)

       Opt@PrintTimings   = False
       Opt@Debug          = False
       
     do n=0,nNames-1                           ; loop thru each variable
       var = srcFile->$vNames(n)$              ; read the varible to memory
       print( getvardims( var ) )              ; dimension names
       dimNames = getvardims( var )            ; dimension names
       nDims    = dimsizes( dimNames )         ; dimension size
   
       if ( vNames(n) .ne. LatName .and. vNames(n) .ne. LonName .and. vNames(n) .ne. "lat_bnds" .and. vNames(n) .ne. "lon_bnds" ) then
          if ( nDims .ge. 2 ) then   ; at least two dimension
             if ( dimNames(nDims-1) .eq. LonName .and. dimNames(nDims-2) .eq. LatName ) then
                print( " ... regrid "+ vNames(n)  )
                ;----------------------------------------------------------------------
                ; Set interpolation method
                ;----------------------------------------------------------------------
             
                if ( vNames(n) .eq. "pr" ) then
                   InterpMethod = "conserve"
                else
                   InterpMethod = "conserve"
                  ;InterpMethod = "bilinear"
                end if
                Opt@InterpMethod = InterpMethod
                wgtFileName      = wgtFileName_tmp+"_"+InterpMethod+".nc"   ; wgt file name
                Opt@WgtFileName  = wgtFileName  ; wgt file name

                exist = isfilepresent( wgtFileName )
                if (.not.exist) then
                   print( " ... wgt file does not exist : "+wgtFileName )
                else
                   print( " ... wgt file exists. Setting wgt Opt to True : "+wgtFileName )
                   Opt@SkipWgtGen       = True
                end if
                print(" .................... Regridding weight file : "+wgtFileName )

  
                ;----------------------------------------------------------------------
                ; Apply the weights to a given variable on the NCEP file.
                ;----------------------------------------------------------------------

                if (nDims .eq. 3 ) then ; [time, lat, lon]
                   if ( any(var.eq.var@_FillValue) ) then
                      imask = where(var.ne.var@_FillValue,1,0)  ; mask terrain (time varient for some models....)
                      imask!0 = var!0
                      imask!1 = var!1
                      imask!2 = var!2
                      imask@long_name = "data mask"
                      imask@units     = "none"
                      imask@base_name = var@standard_name   ; mask orgininated from VAR... to be noted in the output file.

                      Opt@SrcMask2D = imask    ; it doesn't work
                      imask_regrid = ESMF_regrid(imask,Opt)  ; alternatively, use the following two lines.
                      imask_regrid = where( imask_regrid .eq. 1 , imask_regrid , imask_regrid@_FillValue  )
                      dstFile->imask_regrid = imask_regrid

                      Opt@DstMask2D = imask_regrid
                   end if

                   var_regrid = ESMF_regrid(var,Opt)

                   if ( any(var.eq.var@_FillValue) ) then
                      var_regrid = where( imask_regrid .eq. 1 , var_regrid, var_regrid@_FillValue )
                      delete( imask )
                      delete( imask_regrid )
                   end if

                end if

                if (nDims .eq. 4 ) then ; [time, plev, lat, lon]
                   imask = where(var.ne.var@_FillValue,1,0)  ; mask terrain (time varient for some models....)
                   imask!0 = var!0
                   imask!1 = var!1
                   imask!2 = var!2
                   imask!3 = var!3
                   imask@long_name = "data mask"
                   imask@units     = "none"
                   imask@base_name = var@standard_name   ; mask orgininated from VAR... to be noted in the output file.
                   
                   Opt@SrcMask2D = imask    ; it doesn't work
                   imask_regrid = ESMF_regrid(imask,Opt)  ; alternatively, use the following two lines.
                   imask_regrid = where( imask_regrid .eq. 1 , imask_regrid , imask_regrid@_FillValue  )
                   dstFile->imask_regrid = imask_regrid

                   Opt@DstMask2D = imask_regrid

                   var_regrid = ESMF_regrid(var,Opt)
                   var_regrid = where( imask_regrid .eq. 1 , var_regrid, var_regrid@_FillValue )
 
                   delete( imask )
                   delete( imask_regrid )
                end if

                if ( nDims .gt. 4 ) then
                   print( " ... more than 4 dimensions")
                   exit
                end if

                print( " ..................................... writing regridded data : "+vNames(n))
                printVarSummary(var_regrid)

                ;----------------------------------------------------------------------
                ; Write output
                ;----------------------------------------------------------------------
                dstFile->$vNames(n)$ = var_regrid   ;output  regridded field
                delete (var_regrid)
             else
                dstFile->$vNames(n)$ = var   ;output fields that don't need to be regridded
                print( " ..................................... writing original data : "+vNames(n))
             end if
           else
             print( " .............. isstring ? " + isstring(var) )
             if ( isstring( var )) then
                var_char = stringtocharacter(var)
                copy_VarAtts( var, var_char )
                var_char!0 = var!0
                dstFile->$vNames(n)$ = var_char    ;output fields that don't need to be regridded
                delete ( var_char )
             else
                dstFile->$vNames(n)$ = var   ;output fields that don't need to be regridded
             end if
             print( " ..................................... writing original data : "+vNames(n))
           end if
        end if
        delete (var)
        delete (dimNames)
        delete (nDims)
      end do
   
   ;----------------------------------------------------------------------
   ; 1) Copy global attributes from the original file.
   ; 2) Add history
   ;----------------------------------------------------------------------
       global = True
       file_atts = getvaratts(srcFile)    ; get global attributes
      
       if (.not.any(ismissing(file_atts))) then
           do i=0,dimsizes(file_atts)-1
             global@$file_atts(i)$  = srcFile@$file_atts(i)$
            ;print("Attribute " + file_atts(i) + " = " + srcFile@$file_atts(i)$)
          end do
       delete( file_atts )
       end if
       global@regridder_name = "ESMF_rec_to_1deg.ncl"
       global@regridder_wgt_filename = wgtFileName
       global@regridded_file_creation = systemfunc( "date" ) + " liang.chen@usask.ca (liang chen)"
       fileattdef( dstFile, global )

       delete( dstFile )
       delete( srcFile )
       delete( OutFileName )
       delete( nNames )
       delete( vNames )
       delete( global )
       delete( Opt )

  end do
    
      
;----------------------------------------------------------------------
end
