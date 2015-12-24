;----------------------------------------------------------------------
; ESMF_genWgts_rec_to_1deg.ncl
;
;
;  Purpose :
;            This is an NCL/ESMF file for generating src and dst SCRIP files
;            and weight file for regridding from a rectilinear grid to a
;            1 degree grid.
;
;            1) rectilinear_to_SCRIP to convert original source rectilinear
;               grid to a SCRIP convention file.
;            2) latlon_to_SCRIP to convert destination lat/lon grid to a
;               SCRIP convention file.
;            3) ESMF_regrid_gen_weights to generate a weight file using 
;               "conserve" and "bilinear" option
;
;            The rectilinear grid is assumed to be contained in a NetCDF file.
; 
;            Search for lines with ";;---Change (likely)" or ";;---Change (maybe)".
;            These are the lines you will likely or maybe have to change.
;
; Usage    : ncl 'ModelName="GPCC"' 'srcFileName="/glade/scratch/chenl/Reanalysis/GPCC/full_data_v6_precip_10.nc"' \
;                'LatName="lat"' 'LonName="lon"' ESMF_genWgts_rec_to_1deg.ncl
; Liang Chen 24 Dec. 2015
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
;---Field name for test plots
   ;varname = "TMP_P8_L100_GLL0"                      ;;---Change (likely)
   ;VarName = "TMP_P8_L100_GLL0"                      ;; ---- for plot title
   ;cnMin   = 0
   ;cnMax   = 800
   ;cnSpace = 40

;---Model name
   ;ModelName = "GPCC"              ;;---Change

;---Output (and input) files
    srcGridName = "src_SCRIP_"+ModelName+".nc"
    dstGridName = "dst_SCRIP_latlon_1deg.nc"
    wgtFileName1 = ModelName+"2DST_weights_latlon_1deg_conserve.nc"
    wgtFileName2 = ModelName+"2DST_weights_latlon_1deg_bilinear.nc"

;---Plot regridded field to check?  (yes = 1, no = 0)
    plot_opt = 0;

;----------------------------------------------------------------------
; Convert original source NCEP grid to a SCRIP convention file.
;----------------------------------------------------------------------

    if ( FileType .eq. "grb2" ) then
         src_file = addfile( srcFileName+".grb2", "r" );
    else
         src_file = addfile(srcFileName,"r")
    end if
    var     = src_file->$varname$
    src_lat = src_file->$LatName$ 
    src_lon = src_file->$LonName$

    Opt                = True
    Opt@ForceOverwrite = True
    Opt@PrintTimings   = True
    Opt@Title          = ModelName

    rectilinear_to_SCRIP(srcGridName,src_lat,src_lon,Opt)

;---Clean up
    delete(Opt)

;----------------------------------------------------------------------
; Convert destination grid to a SCRIP convention file.
;----------------------------------------------------------------------
    Opt                = True
;    Opt@LLCorner       = (/ 20.5d, -140.5d/)
;    Opt@URCorner       = (/ 55.5d, -55.5d/)
;    Opt@LLCorner       = (/ 5.5d, -170.5d/)
;    Opt@URCorner       = (/ 65.5d, -35.5d/)
    Opt@LLCorner       = (/ -89.5d, -179.5d/)
    Opt@URCorner       = (/  89.5d,  179.5d/)

    Opt@ForceOverwrite = True
    Opt@PrintTimings   = True

    latlon_to_SCRIP(dstGridName,"1deg",Opt)

;---Clean up
    delete(Opt)

;----------------------------------------------------------------------
; Generate the weights that take you from the NCEP grid to a
; 5x5 degree grid. : conserve method
;----------------------------------------------------------------------
    InterpMethod             = "conserve"

    Opt                      = True
    Opt@InterpMethod         = InterpMethod
    Opt@DstRegional          = True
    Opt@ForceOverwrite       = True
    Opt@PrintTimings         = True
    Opt@Debug                = True

    ESMF_regrid_gen_weights(srcGridName,dstGridName,wgtFileName1,Opt)

    delete(Opt)

;----------------------------------------------------------------------
; Generate the weights that take you from the NCEP grid to a
; 5x5 degree grid. : bilinear method
;----------------------------------------------------------------------
    InterpMethod             = "bilinear"

    Opt                      = True
    Opt@InterpMethod         = InterpMethod
    Opt@DstRegional          = True
    Opt@ForceOverwrite       = True
    Opt@PrintTimings         = True
    Opt@Debug                = True

    ESMF_regrid_gen_weights(srcGridName,dstGridName,wgtFileName2,Opt)

    delete(Opt)

;----------------------------------------------------------------------
; Apply the weights to a given variable on the CMIP5 file.
;   conserve method
;----------------------------------------------------------------------
    InterpMethod       = "conserve"

    Opt                = True
    Opt@PrintTimings   = True

;---In V6.1.0, coordinates and attributes are copied automatically
    var_regrid = ESMF_regrid_with_weights(var,wgtFileName1,Opt)
    printVarSummary(var_regrid)

;Open output file as a check ...
    ncfile = "test"+ModelName+"_"+InterpMethod+".nc"   ;create temporary outputfile name...
    if (isfilepresent( ncfile ))
       system ("/bin/rm "+ncfile)
    end if
    ncdf = addfile(ncfile,"c")
    ncdf->var_regrid = var_regrid   ;output  regridded field

;----------------------------------------------------------------------
; Apply the weights to a given variable on the CMIP5 file.
;   bilinear method
;----------------------------------------------------------------------
    InterpMethod       = "bilinear"

    Opt                = True
    Opt@PrintTimings   = True

;---In V6.1.0, coordinates and attributes are copied automatically
    var_regrid = ESMF_regrid_with_weights(var,wgtFileName2,Opt)
    printVarSummary(var_regrid)

;Open output file as a check ...
    ncfile = "test"+ModelName+"_"+InterpMethod+".nc"   ;create temporary outputfile name...
    if (isfilepresent( ncfile ))
       system ("/bin/rm "+ncfile)
    end if
    ncdf = addfile(ncfile,"c")
    ncdf->var_regrid = var_regrid   ;output  regridded field


;----------------------------------------------------------------------
; Plot the original and regridded data on a panel plot
;----------------------------------------------------------------------

  if ( plot_opt .eq. 1) then
       wks = gsn_open_wks("png","ESMF_rec_to_1deg_"+ModelName)             ; sample figure
       gsn_define_colormap(wks,"gui_default")      ; choose colormap
   
       res                     = True              ; Plot mods desired.
       res@gsnDraw             = False             ; We will panel later.
       res@gsnFrame            = False
   
       res@gsnMaximize         = True              ; Maximize plot
       
       res@mpMaxLatF           = 55.                ; choose map range
       res@mpMinLatF           = 20.
       res@mpMaxLonF           = -55.               ; choose map range
       res@mpMinLonF           = -140.
   
       res@cnFillOn            = True              ; color plot desired
       res@cnLinesOn           = False             ; turn off contour lines
       res@cnLineLabelsOn      = False             ; turn off contour lines
   
       res@cnLevelSelectionMode =  "ManualLevels"   ; manual levels
       res@cnMinLevelValF       = cnMin             ; min level
       res@cnMaxLevelValF       = cnMax             ; max level
       res@cnLevelSpacingF      = cnSpace           ; interval
   
       res@lbLabelBarOn        = False              ; Labelbar will be in panel
   
   ;---Plot data on original grid
       res@gsnAddCyclic = False
   
      ;dims = tostring(dimsizes(var(:,:)))
      ;dims = tostring(dimsizes(var(0,:,:)))
       dims = tostring(dimsizes(var(0,0,:,:)))
       res@tiMainString = "monthly mean "+VarName+" : original data (" + \
                          str_join(dims," x ") + ")"
      ;plot_orig = gsn_csm_contour_map(wks,var(:,:),res)     
       plot_orig = gsn_csm_contour_map(wks,var(0,:,:),res)     
   
   ;---Plot data interpolated onto 1-degree grid
       res@gsnAddCyclic = False
   
      ;dims = tostring(dimsizes(var_regrid(:,:)))
       dims = tostring(dimsizes(var_regrid(0,:,:)))
       res@tiMainString = "Monthly mean "+VarName+" : regridded to 1-deg grid (" +\
                          str_join(dims," x ") + ")"
      ;plot_regrid = gsn_csm_contour_map(wks,var_regrid(:,:),res)     
       plot_regrid = gsn_csm_contour_map(wks,var_regrid(0,:,:),res)     
   
   ;---Resources for paneling
       pres                  = True
       pres@gsnMaximize      = True
       pres@gsnPanelLabelBar = True
   
       gsn_panel(wks,(/plot_orig,plot_regrid/),(/2,1/),pres)
  end if
;----------------------------------------------------------------------
;----------------------------------------------------------------------
end
