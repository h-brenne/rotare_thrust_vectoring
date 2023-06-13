"""Generate airfoil polars automatically using XFOIL

 Rotare requires the input of airfoil polars to interpolate properly the lift
 and drag coefficient of the various elements.
 This script automates the generation of these input polars to save some time.

 Args:
    - airfoil : str
        Arfoil to use, either in the form of 'naca0012' or name of the DAT-file
        with the coordinates

 Script defaults:
    - Reynolds : 1e5, 5e5, 1e6, 1.5e6, 2e6, 5e6, 1e7
    - AOA : -25 to 25 with a step of 0.5
    - Iter : 100

 ------------------------------------------------
 (c) Copyright 2022 University of Liege
 Author: Thomas Lambert <t.lambert@uliege.be>
 ULiege - Aeroelasticity and Experimental Aerodynamics
 MIT License
"""

# Imports
import sys
import os
import numpy as np
import aeropy.xfoil_module as xf


def main():
    """Creates polar files for each reynolds"""

    airfoil = parse_inputs()
    reynolds = [re * 100000 for re in [0.1, 0.5, 1]]
    aoa = list(np.arange(-20, 25, 0.5))

    i = 1
    for re in reynolds:
        print("%d/%d - Calculating polar for Re=%ge5" % (i, len(reynolds), re / 1e5))
        i = i + 1

        if airfoil.startswith("naca"):
            xf.call(
                airfoil,
                alfas=aoa,
                output="Polar",
                Reynolds=re,
                plots=False,
                NACA=True,
                iteration=5000,
            )
        else:
            if os.path.exists(airfoil) or os.path.exists(airfoil + ".dat"):
                xf.call(
                    airfoil,
                    alfas=aoa,
                    output="Polar",
                    Reynolds=re,
                    plots=False,
                    NACA=False,
                    iteration=5000,
                )
            else:
                raise ValueError("Airfoil file not foud")

    cleanup(airfoil)


def parse_inputs():
    """Proper parsing of inputs"""
    airfoil = sys.argv[1]

    return airfoil


def cleanup(airfoil):
    """Remove temp files and rename files properly"""

    cwd = os.getcwd()

    # Remove useless files
    safe_remove(":00.bl")

    # Add proper extension to generated files
    for file in os.listdir(cwd):
        if file.startswith("Coordinates_"):
            safe_rename(file, airfoil + ".dat")
        elif file.startswith("Polar_"):
            safe_rename(file, file + ".txt")


def safe_remove(file):
    """Safely remove a file"""
    if os.path.exists(file):
        os.remove(file)


def safe_rename(old, new):
    """Safely rename a file"""

    if os.path.exists(new):
        os.remove(new)

    os.rename(old, new)


# Only run when file is directly executed
if __name__ == "__main__":
    main()
