#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# vim: noet number ts=4 ai nowrap

# better variant TODO should be a B-spline

import math

th = 1.5;

from sys import argv

th = 1.5	# base thickness of material

lb, rb, tab = '{', '}', '\t'

#r0 = horns['horn0']['r0']
#scale0 = horns['horn0']['scale']

class HornCirc:
	default_ratio = 1/2
	default_r0 = 30
	default_lDiv = 8#32
	default_rDiv = 4
	default_color = '#c0c0c0'

	#def __init__(self, C, **kwargs):
	def __init__(self, l, C, **kwargs):
		self.len = l								# length of this section = 2*pi*R*elev/360
		self.C = C									# curvature of this section

		#self.R = kwargs.pop('R',30)					# radius of rotation (aka 'length' of spline)
		self._r0 = kwargs.pop('r0',None)				# radius at beginning of horn
		self._r1 = kwargs.pop('r1',None)				# radius at end of horn
		#self.elev = kwargs.pop('elev',180)	# elev angle ; cannot be zero
		self.roll = kwargs.pop('roll',0)			# roll angle

		self.rDivs = kwargs.pop('rDivs', 3)			# divisions of the base polyhedron	-> radial resolution
		self.lDivs = kwargs.pop('lDivs', 1)			# divisions of base circle	-> resolution along path
		self._zRot = kwargs.pop('zRot', None)				# initial rotation of poly (roll axis)
		self._twist = kwargs.pop('twist', None)			# twist of polys on roll axis along length of body ; relative to elev = 90

		self._color = kwargs.pop('color', None)

	
	def __repr__(self):
		return f"<class HornCirc @ {hex(id(self))}>"
	
	@property
	def R(self):
		return 1/self.C if self.C != 0 else float('inf')

	def elev(self, delta = False):
		"""
			l=2*pi*R*elev/360

			delta ellongates the horn a little bit, to prevent artefacts
		"""
		return (self.len + 0.01 if delta else self.len)*360/(2*math.pi*self.R)

	@property
	def r0(self):
		try:					return self._prev.r1 if self._r0 is None else self._r0
		except AttributeError:	return self.default_r0 if self._r0 is None else self._r0
	@property
	def r1(self):
		try:					return self._prev.r1*self.default_ratio if self._r1 is None else self._r1
		except AttributeError:	return self.default_r0*self.default_ratio if self._r1 is None else self._r1
	@property
	def lDivs(self):
		try:					return self._prev.lDivs if self._lDivs is None else self._lDivs
		except AttributeError:	return self.default_lDiv if self._lDivs is None else self._lDivs
	@lDivs.setter
	def lDivs(self, value):
		self._lDivs = round(value)
	@property
	def rDivs(self):
		try:					return self._prev.rDivs if self._rDivs is None else self._rDivs
		except AttributeError:	return self.default_rDiv if self._rDivs is None else self._rDivs
	@rDivs.setter
	def rDivs(self, value):
		self._rDivs = round(value)
	@property
	def zRot(self):
		try:					return self._prev.zRot+self._prev.morezRot+self.roll if self._zRot is None else self._zRot#+self.roll
		except AttributeError:	return 0 if self._zRot is None else self._zRot#+self.roll
	@property
	def morezRot(self):
		if self.elev() > 0:
			return self._twist/self.elev()*90
		else:
			return self._twist/self.elev()*90
	@property
	def color(self):
		#return ""
		try:					color = self._prev.color if self._color is None else self._color
		except AttributeError:	color = self.default_color if self._color is None else self._color
		return f'color("{color}")'

	@property
	def twist(self):
		#try:					return self._prev.twist if self._twist is None else self._twist/self.elev*self.lDivs*4
		try:					return self._prev.twist if self._twist is None else self._twist/self.elev()/self.lDivs*90
		except AttributeError:
			#return 0 if self._twist is None else self._twist/self.elev*self.lDivs*4
			return 0 if self._twist is None else self._twist/self.elev()/self.lDivs*90

	@twist.setter
	def twist(self, value):
		self._twist = value


	def append( self, obj ):
		self._next = obj
		obj._prev = self
		return self
	
	def next(self, i):
		try:
			return f"{0*i*tab}{self._next.polyhedron(i)}"
		except AttributeError:
			return f';// end of horn reached after {i} iterations'
	
	def polyhedron(self, i = 0):
		def polyhedron(rr,radius,r1, segments, rAngle, rSegments, zRot, twist):
			stepAngle = 360/segments
			rotAngle = rAngle/rSegments
			points = '['				# string with the vector of point-vectors
			faces = '['				 # string with the vector of face-vectors
			sprs = (r1/radius-1)/rSegments				  # scale per rSegment
		
			# construct all points
			for j in range(0,rSegments+1):
				angle = j*rotAngle
				for i in range(0,segments):
					xflat = (math.sin(math.radians(i*stepAngle+zRot+j*twist))*radius)			# x on base-circle
					xscaled = xflat*(1 + sprs*j) + rr					   # x scaled (+ rr -> correction of centerpoint
					xrot = math.cos(math.radians(angle))*xscaled				# x rotated
					yflat = (math.cos(math.radians(-i*stepAngle-zRot-j*twist))*radius)		   # y on base-circle
					yscaled = yflat*(1 + sprs*j)						# y scaled
					z = math.sin(math.radians(angle))*xscaled				   # z rotated
					string  = '[{},{},{}],'.format(xrot,yscaled,z)
					points += string
		
			points += ']' 
		
			# construct all faces
			# bottom
			f = '['
			for i in range(segments-1,-1,-1):
				f += '{},'.format(i)
			f += '],'
			faces += f				  # add bottom to faces
		
			# all faces on the side of the tube
			for p in range(0, segments*rSegments):
				p1 = p
				p2 = p + 1 -segments if p%segments == segments-1 else p +1
				p3 = p + segments
				p4 = p3 + 1 -segments if p%segments == segments-1 else p3 +1
				f = '[{},{},{}],'.format(p1,p4,p3)
				faces += f
				f = '[{},{},{}],'.format(p1,p2,p4)
				faces += f
			# top
			f = '['
			for i in range(segments*rSegments,segments*(rSegments+1)):
				f += '{},'.format(i)
			f += ']'
			faces += f				  # add top to faces
			faces += ']'
		
			string = 'polyhedron( points = {}, faces = {});'.format(points,faces)
			return string	

		try:
			def_elev = self._prev.elev()
			prefix = f"""\
	{i*tab}rotate([0,-{self._prev.elev()},0])
	{i*tab}translate([{self._prev.R},0,0])"""
		except AttributeError:
			def_elev = 0
			prefix = "// TODO rotate/translate to start at origin"
		
		return f"""{prefix}
	{i*tab}rotate([0,0,{self.roll}])
	{i*tab}translate([-{self.R},0,0])
	{i*tab}{lb}
	{i*tab}{f"translate([{2*self.R},0,0]) mirror([1,0,0]) mirror([0,1,0])" if self.elev() < 0 else ''}
	{i*tab}	{self.color}
	{i*tab}	{polyhedron(
		   			self.R,
		   			self.r0,
		   			self.r1,
		   			self.rDivs,
		   			abs(self.elev(True)),
		   			self.lDivs,
		   			self.zRot,
		   			self.twist,
		   )}
	{i*tab}{f"translate([{2*self.R},0,0]) rotate([0,0,0]) mirror([0,1,0]) mirror([1,0,0]) mirror([0,0,1])" if self.elev() < 0 else ''}{self.next(i+1)}
	{i*tab}{rb}
"""



def write(horns):
	with open(f'horns.scad','w') as scadfile:
		for index in horns.keys():
			scadfile.write('module '+str(index)+'() {\n')
			scadfile.write("\t" + horns[index].polyhedron() + '\n' )
			scadfile.write('}\n\n')

		for index in horns.keys():
			scadfile.write(f"{index}();")
			scadfile.write('\n')

		scadfile.close()

