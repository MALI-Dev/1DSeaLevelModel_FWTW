# 1DSeaLevelModel_FWTW

This repository houses a 1D pseudo-spectral forward sea-level model with the time window algorithm introduced in Han et al. (in review, GMD).

The sea-level model in this repository branches out from the ice-age sea-level code (sl_model.f90 housed in the other repository "SL_MODEL", https://github.com/GomezGroup/SL_MODEL) and implements forward modelling algorithm developed by Gomez et al. (2010) and the new time window algorithm developed by Han et al. (in review, Geoscientific Model Development); hence, the name of the model is SL_MODEL_FWTW (ForWard TimeWindow). This model can be configured to run either as a standalone or coupled to a dynamic ice-sheet model with or without activating the time window algorithm.

Note: The fundamental difference between the ice-age sea-level calculations and forward sea-level calculations is the previous knowledge of the inital topography boundary condition - it is unknown in the ice-age calculations whereas known in the forward calculation.

Full references on:

Ice-age sea-level algorithm: Kendall et al., On post-glacial sea level II. Numerical formulation and comparative results on spherically symmetric models, GJI, 2005.

Forward sea-level algorithm: Gomez et al., A new projection of sea level change in response to collapse of marinesectors of the Antarctic Ice Sheet, GJI, 2010.

Ice-sheet - sea-level coupling algorithm: Gomez et al., Evolution of a coupled marine ice sheet-sea level model. JGR: Earth Surface, 2012.

Time window algorithm: Han et al., Capturing the Interactions Between Ice Sheets, Sea Level and the Solid Earth on a Range of Timescales: A new “time window” algorithm, GMD, in review.

This code is made public for the benifit of scientific community. Please cite it with the DOI provided below: DOI: (TO BE ACQUIRED AND UPDATED ONCE THE CODE GETS A DOI UPON THE ACCEPTANCE BY GMD)
