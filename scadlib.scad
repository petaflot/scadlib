/*

scadlib - my OpenSCAD library to stop wasting so much time on stupid things
like forgetting not to write cylinder([L,W,H]) and positionning amongst other
things.

author: dl
date:	2015-06-04
v:	0.1

date:	2016-04-06
v:	0.1b
	- label field to output board dimensions when it's a "cube" and label is set

date:	2016-04-11
v:	0.1c
	- included rondelle(), mygear(), bevel_gears() and dependency to parametric_involute_gears.scad


	Licence: free to use and fully enjoy for any purpose that benefits to mankind and nature in particular

BUGS: 
	- prism(5,[...]) has double the sides! watch for odd numbers :-/
*/


/*
 ********************************
 *								*
 *	NICE FUNCTIONS				*
 *								*
 ********************************
 */


module ref_arrow()
{
	cylinder(2,0,1);
	translate([0,0,2])
	cylinder(18,1,1);
	translate([0,0,20])
	cylinder(5,3,0);
}

/*
 * this creates a mobile referential / axii
 */
module ref( scale = [1,1,1] )
{
	scale(scale)
	{
		color("red")
		rotate([0,90,0])
		ref_arrow();
		color("green")
		rotate([-90,0,0])
		ref_arrow();
		color("blue")
		ref_arrow();
	}
}

/*
 * creates a sector of a "cylinder" ; very useful for cuts
 */
module sector(r,h,a)
{
	if ( a == 360 ) {
		cylinder(h,r/2,r/2);
	} else {
		intersection()
		{
			cylinder(h,r/2,r/2);
			if ( a <= 90 ) {
				intersection() {
					cube([r/2,r/2,h]);
					rotate([0,0,-90+a]) cube([r/2,r/2,h]);
				}
			} else if ( a <= 180 ) {
				union() {
					cube([r/2,r/2,h]);
					rotate([0,0,a]) translate([0,-r/2,0]) cube([r/2,r/2,h]);
				}
			} else {
				union() {
					translate([-r/2,0,0]) cube([r,r/2,h]);
					rotate([0,0,a-180]) translate([-r/2,0,0]) cube([r,r/2,h]);
				}
			}
		}
	}
}

/*
 * prism()
 *
 * treats all basic solids (cubes and variations of the prismatic cylinder) the
 * same way when it comes to positionning (the cylinder is enclosed in the box
 * defined by the cube of same parameters). Elliptical cylinders are made
 * available, as well as the "clavette" and a variety of hollow prisms.

PARAMETERS

* _fn_ number of faces. 0 is a special case for the cube, it defaults to this base "box" in which to fit the solid. same as cube() parameters
* _center_  whether to center the solid on each axis.  defaults to [true,true,false], which is the default behaviour of the cylinder, while [false,false,false] will mimic the behaviour of the cube() primitive
* _oblong_  do we treat an elongated cylinder/prism as an ellipse (false) or as a hull() of two smaller cylinders (default: true). 
* _zrot_ makes sense only if "oblong" is turned on. the rotation for each of the two hull cylinders on their own z axis. this allows you to create cool shapes and fix some issues at the same time.
* _shell_ defaults to 0, a full (non-hollow) solid. higher values will create some sort of extruded tube.

LIMITATIONS/FEATURES

     prism(5,[20,40,10],shell=5) != rotate([0,0,90]) prism([40,20,10],shell=5)

     * thickness of the shell will not always be the constant along the perimeter. patches welcome.


*/
module prism(fn, base=[1,1,1], center=[true,true,false], oblong=true, zrot=0, shell=0, label="", ref = 0)
{
	oblong_xoffset = base[0]>base[1]?((base[0]/2-(1+sqrt(2))*shell)+(base[0]/2-2*shell))/2:0;
	oblong_yoffset = base[0]>base[1]?0:((base[1]/2-(1+sqrt(2))*shell)+(base[1]/2-2*shell))/2;

	// TODO allow negative numbers in dimensions... usefeul when one of center values is false ; something like
	// if ( base[0] < 0 ) {	mirror([1,0,0])	}

	//if ( fn == 0 )
	//{
	//	echo(base);
	//}
	if ( ref != 0 )
	{
		ref([ref,ref,ref]);
	}

	if (fn == 0)
	{
		// special case for a cube
		if (label!="")
		{
			echo(label);
			echo(base);
		}

		translate([center[0]?-base[0]/2:0,center[1]?-base[1]/2:0,center[2]?-base[2]/2:0]) 
		if (!shell)
		{
			cube(base);
		} else {
			difference()
			{
				cube(base);
				translate([shell,shell,-shell]) cube([base[0]-2*shell,base[1]-2*shell,base[2]+2*shell]);
			}
		}
	} else {
		translate([center[0]?0:base[0]/2,center[1]?0:base[1]/2,center[2]?-base[2]/2:0]) 
		if (!oblong)
		{
			if (!shell)
			{
				scale([base[0]/2,base[1]/2,1]) cylinder(base[2],1,1,$fn=fn);
			} else {
				difference()
				{
					scale([base[0]/2,base[1]/2,1]) cylinder(base[2],1,1,$fn=fn);
					translate([0,0,-shell/2]) scale
						([
							//base[0]>base[1]?1:base[0]/2-shell,
							//base[0]>base[1]?1:(base[1]/2-2*shell*base[0]/base[1]),
							base[0]/2-shell,
							base[1]/2-shell,
							1
						]) 
						cylinder(base[2]+shell,1,1,$fn=fn);
				}
			}
		} else {	// oblong == true
			if (!shell)
			{
				hull()
				{
					translate([base[0]>base[1]?(base[0]-base[1])/2:0,base[0]<base[1]?(base[0]-base[1])/2:0,0]) 
						scale([base[0]>base[1]?base[1]/2:base[0]/2,base[0]>base[1]?base[1]/2:base[0]/2,1]) 
						rotate([0,0,  0-zrot]) cylinder(base[2],1,1,$fn=fn);
					translate([base[0]>base[1]?(base[1]-base[0])/2:0,base[0]<base[1]?(base[1]-base[0])/2:0,0]) 
						scale([base[0]>base[1]?base[1]/2:base[0]/2,base[0]>base[1]?base[1]/2:base[0]/2,1]) 
						rotate([0,0,180+zrot]) cylinder(base[2],1,1,$fn=fn);
				}
			} else {	// shell != 0
				difference()
				{
					hull()
					{
						translate([base[0]>base[1]?(base[0]-base[1])/2:0,base[0]<base[1]?(base[0]-base[1])/2:0,0]) 
							scale([base[0]>base[1]?base[1]/2:base[0]/2,base[0]>base[1]?base[1]/2:base[0]/2,1]) 
							rotate([0,0,  0-zrot]) cylinder(base[2],1,1,$fn=fn);
						translate([base[0]>base[1]?(base[1]-base[0])/2:0,base[0]<base[1]?(base[1]-base[0])/2:0,0]) 
							scale([base[0]>base[1]?base[1]/2:base[0]/2,base[0]>base[1]?base[1]/2:base[0]/2,1]) 
							rotate([0,0,0+zrot]) cylinder(base[2],1,1,$fn=fn);
					}
					hull()
					{
						translate([base[0]>base[1]?oblong_xoffset-4*shell/5:0,base[0]>base[1]?0:oblong_yoffset-4*shell/5,-shell])
						scale([base[0]>base[1]?base[1]/2-shell:base[0]/2-shell,
							base[0]>base[1]?base[1]/2-shell:base[0]/2-shell,1]) 
						rotate([0,0,-(0+zrot+fn/4)]) 
						cylinder(base[2]+2*shell,1,1,$fn=fn);
						
						translate([base[0]>base[1]?-oblong_xoffset+4*shell/5:0,base[0]>base[1]?0:-oblong_yoffset+4*shell/5,-shell])
						scale([base[0]>base[1]?base[1]/2-shell:base[0]/2-shell,
							base[0]>base[1]?base[1]/2-shell:base[0]/2-shell,1]) 
						rotate([0,0,zrot+fn/4]) 
						cylinder(base[2]+2*shell,1,1,$fn=fn);
					}
				}
			}
		}
	}
}

module torus( r1 = 5, r2 = 10, angle )
{
	rotate_extrude()
	{
		translate([r2,0,0])
		circle(r1);
	}
}

/*
 * historical function that makes a washer. candidate for removal
 */
module rondelle(r,th,bore_radius,center=false)
{
	difference()
	{
		cylinder(th,r,r,center=center,$fn=4);
		//cylinder(th,2*r,0,center=center,$fn=3);
		cylinder(th+adj,bore_radius,bore_radius,center=center);
	}
}


