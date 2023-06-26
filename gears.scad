// vim: noet ts=4 number
use <parametric_involute_gear.scad>

/*
 * my wrapper for involute gear around http://www.thingiverse.com/thing:3575
 *
 * includes:  
 * - simple rendering (cylinder with $fn=num_teeth)
 * - gear centered on its z axis
 * - "auto" twist with 'mult' option
 *
 * arguments:
 * - r					radius of gear
 * - th					thickness of gear
 * - bore_radius		radius of center bore (gear axis)
 * - twist				twist angle of gear
 * - circles			number of holes in the gear. TODO, because conflicts with 'mult'
 * - tpr				"teeth per radius" ratio, or
 *   					"frequency" multiplicator of the gear (integer multiplication of the number of teeth
 *   					must be constant across gear train
 * - mult				number of layers with alternating twist. TODO: make twist evolution a function (eg. sine())
 * - simple_rendering	true to show only cylinders instead of full gears ; defaults to false
 */
adj = 0;
module mygear(r,th,bore_radius=1,twist=15,circles=6,tpr=1,mult=2,simple_rendering=false)
{
	//echo("num teeth",r*tpr);
	if (simple_rendering )
	{
		difference()
		{
			cylinder(th,r,r,center=true,$fn=r*tpr);
			cylinder(th+adj,bore_radius,bore_radius,center=true,$fn=6);
		}
	}
	else
	{
		for (i=[0:mult-1])
		{
			translate([0,0,-i*th/mult+1*th/2])
			translate([0,0,i/2==round(i/2)?0:-th/mult])
			mirror([0,0,i/2==round(i/2)?1:0])
			gear(circular_pitch=360/tpr,
				number_of_teeth=r*tpr,
				gear_thickness = th/mult,
				rim_thickness = th/mult,
				hub_thickness = th/mult,
				circles=circles,
				bore_diameter = bore_radius*2,
				twist=twist/r*th);
		}
	}
}

/*
 * my bevel_gears wrapper. makes it easier to generate split matching bevel gears
 *
 * TODO: fix simple_rendering
 */
module bevel_gears (
	gear1_teeth = 41,
	gear2_teeth = 7,
	axis_angle = 90,
	outside_circular_pitch=1000,	// 1000
	draw_gear = 0,
	bore_radius = 1)
{
        outside_pitch_radius1 = gear1_teeth * outside_circular_pitch / 360;
        outside_pitch_radius2 = gear2_teeth * outside_circular_pitch / 360;
        pitch_apex1=outside_pitch_radius2 * sin (axis_angle) +
                (outside_pitch_radius2 * cos (axis_angle) + outside_pitch_radius1) / tan (axis_angle);
        cone_distance = sqrt (pow (pitch_apex1, 2) + pow (outside_pitch_radius1, 2));
        pitch_apex2 = sqrt (pow (cone_distance, 2) - pow (outside_pitch_radius2, 2));
        //echo ("cone_distance", cone_distance);
        pitch_angle1 = asin (outside_pitch_radius1 / cone_distance);
        pitch_angle2 = asin (outside_pitch_radius2 / cone_distance);
        //echo ("pitch_angle1, pitch_angle2", pitch_angle1, pitch_angle2);
        //echo ("pitch_angle1 + pitch_angle2", pitch_angle1 + pitch_angle2);

        rotate([0,0,90])
        //translate ([0,0,pitch_apex1+20])
        {
		if (draw_gear == 1 || draw_gear == 0)
		{
			//if ( false )
			if ( simple_rendering )
			{
				translate([0,0,-cone_distance]) intersection()
				{	
					difference()
					{
						translate([0,0,cone_distance/3]) cylinder(2/3*cone_distance,outside_pitch_radius1,outside_pitch_radius1,$fn=gear1_teeth);
						translate([0,0,-adj]) cylinder(cone_distance+2*adj,bore_radius,bore_radius);
					}
					cylinder(cone_distance,outside_pitch_radius1*sqrt(2),0,$fn=gear1_teeth);
				}
			} else {
				translate([0,0,-pitch_apex1])
				{
				bevel_gear (
					number_of_teeth=gear1_teeth,
					cone_distance=cone_distance,
					pressure_angle=30,
					bore_diameter=2*bore_radius,
					outside_circular_pitch=outside_circular_pitch);
				}
			}
		}
		if (draw_gear == 2 || draw_gear == 0)
		{
			rotate([0,-(pitch_angle1+pitch_angle2),0])
			{
			//if ( false )
			if ( simple_rendering )
			{
				translate([0,0,-cone_distance]) difference()
				{	
					cylinder(cone_distance,outside_pitch_radius2*sqrt(2),0,$fn=gear2_teeth);
					translate([0,0,-adj]) cylinder(cone_distance+2*adj,bore_radius,bore_radius);
				}
			} else {
				translate([0,0,-pitch_apex2])
				bevel_gear (
					number_of_teeth=gear2_teeth,
					cone_distance=cone_distance,
					pressure_angle=30,
					bore_diameter=2*bore_radius,
					outside_circular_pitch=outside_circular_pitch);
				}
			}
		}
  	}
}
 

