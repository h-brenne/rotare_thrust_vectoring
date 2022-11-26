# Airfoil data

Rotare requires the input of airfoil polars to properly interpolate the lift and
drag coefficient of each element. These polars can be directly provided or
generated using external tools such as XFOIL or XFLR5.

The following process explains how to generate such polars and transform them in
a structure to be imported in Rotare. A more complete description is provided in
the complete manual of Rotare.

## polargenerator.py

**polargenerator** is a small script that will run XFOIL in order to generate
the airfoil polars. This script uses the [aeropy] library, follow the
instructions on the Github to install it properly. (_Note: this is not the same
`aeropy` than the one installed through `pip`).

The usage is straightforward:

```bash
python polargenerator <airfoil>
```

It can either accept a NACA airfoil as input or a file with the airfoil
coordinates. Example:

```bash
python polargenerator 'naca0012'
python polargenerator 'myairfoil.dat'
```

Note that if the airfoil coordinates are provided though a DAT-file, the need to
be formatted according to the `Selig` convention (see "[Airfoil Format]" section
on the UIUC Airfoil Database). A Matlab utility is provided with the `af_tools`
library to convert the Ledneicer format into Selig format.

## MAT-file

Once the raw XFOIL data have been generated for a given airfoil, they need to be
converted into a structure that will be understood by Rotare. This is done using
the `xf2mat` function provided by the `af_tools` library.

[Airfoil Format]: https://m-selig.ae.illinois.edu/ads.html
[aeropy]: https://github.com/leal26/AeroPy
