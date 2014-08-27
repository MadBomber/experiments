"""Clock for VPython - Complex (cx@cx.hu) 2003. - Licence: Python

Usage:

from visual import *
from cxvp_clock import *

clk=Clock3D()
while 1:
    rate(1)
    clk.update()

See doc strings for more.
Run this module to test clocks.

TODO: More types of clocks, such as 3D digital,
church clock, hour-glass, pendulum clock, stopper, etc...

Modifications:
2003.01.23. - Complex (cx@cx.hu): First release
2003.01.23. - Complex (cx@cx.hu): now gmtime imported correctly
"""

__all__=['Clock3D']

from visual import *
from visual.text import text
from time import time,localtime,gmtime
from math import sin,cos,pi

def Clock3D(clock_type='analog',*args,**kw):
    """Create a clock with specified type,
    keyword arguments are passed through,
    returns a VPython object derived from frame"""
    if clock_type=='analog': return AnalogClock(*args,**kw)
    raise ValueError('Invalid 3D clock type: %r'%(type,))

class Base(object):
    """Base class to pass specific keyword
    arguments with convenient defaults"""
    def __init__(self,kwlist={},*args,**kw):
	self.kwlist=kwlist
	for k,v in kwlist.items():
	    if kw.has_key(k):
		v=kw[k]
		del kw[k]
	    self.__dict__[k]=v
	self.args=args
	self.kw=kw

class AnalogClock(Base):
    """Analog clock, keyword arguments:
    frame=reference frame to use (default: None),
    pointers=pointers to display, cobination of characters 'h', 'm' and 's' (default: 'hms')
    ring_color=color of ring around the clock (default: color.yellow)
    back_color=color of clock's back plate (default: color.white)
    big_tick_color=color of big ticks (at 12,3,6,9 hours) (default: color.red)
    small_tick_color=color of small ticks (at 1,2,4,5,7,8,10,11 hours) (default: color.blue)
    minute_dot_color=color of minute dots between ticks (default: (0.4,0.4,0.4))
    number_color=color of hour numbers (default: color.black)
    hour_pointer_color=color of hour pointer (default: color.red)
    minute_pointer_color=color of hour pointer (default: color.blue)
    second_pointer_color=color of hour pointer (default: (0.4,0.4,0.4))
    """
    def __init__(self,*args,**kw):
	"""Create primitives of clock"""
	Base.__init__(self,{
	    'frame':None,
	    'pointers':'hms',
	    'ring_color':color.yellow,
	    'back_color':color.white,
	    'big_tick_color':color.red,
	    'small_tick_color':color.blue,
	    'minute_dot_color':(0.4,0.4,0.4),
	    'number_color':color.black,
	    'hour_pointer_color':color.red,
	    'minute_pointer_color':color.blue,
	    'second_pointer_color':(0.4,0.4,0.4)},*args,**kw)
	if not self.frame: self.frame=frame(*self.args,**self.kw)
	pl=list(self.pointers)
	hp,mp,sp='h' in pl,'m' in pl,'s' in pl
	ring(frame=self.frame, axis=(0,0,1), radius=1, thickness=0.05, color=self.ring_color)
	cylinder(frame=self.frame, pos=(0,0,-0.03), axis=(0,0,0.02), radius=1, color=self.back_color)
	for i in range(60):
	    a=pi*i/30.0
	    if i%5==0:
		j=i/5
		if j%3: c,h=self.small_tick_color,0.06
		else: c,h=self.big_tick_color,0.12
		box(frame=self.frame, pos=(0.99,0,0), length=0.14, height=h, width=0.12, color=c).rotate(angle=a, axis=(0,0,1), origin=(0,0,0))
		t=text(pos=(0.8*sin(a),0.8*cos(a)-0.06,0), axis=(1,0,0), height=0.12, string=str(j+12*(not j)), color=self.number_color, depth=0.02, justify='center')
		for o in t.objects: o.frame.frame=self.frame
	    else:
		sphere(frame=self.frame, pos=(1,0,0.05), radius=0.01, color=self.minute_dot_color).rotate(angle=a, axis=(0,0,1), origin=(0,0,0))
	if hp:
	    self.hf=hf=frame(frame=self.frame)
	    cylinder(frame=hf, pos=(0,0,-0.01), axis=(0,0,0.02), radius=0.08, color=self.hour_pointer_color)
	    box(frame=hf, pos=(0.25,0,0.005), axis=(0.5,0,0), height=0.04, width=0.01, color=self.hour_pointer_color)
	else: self.hf=None
	if mp:
	    self.mf=mf=frame(frame=self.frame)
	    cylinder(frame=mf, pos=(0,0,0.01), axis=(0,0,0.02), radius=0.06, color=self.minute_pointer_color)
	    box(frame=mf, pos=(0.35,0,0.025), axis=(0.7,0,0), height=0.03, width=0.01, color=self.minute_pointer_color)
	else: self.mf=None
	if sp:
	    self.sf=sf=frame(frame=self.frame)
	    cylinder(frame=sf, pos=(0,0,0.03), axis=(0,0,0.02), radius=0.04, color=self.second_pointer_color)
	    box(frame=sf, pos=(0.4,0,0.045), axis=(0.8,0,0), height=0.02, width=0.01, color=self.second_pointer_color)
	else: self.sf=None
	self.update()
    def update(self,unixtime=None,gmt=0):
	"""Update clock to specific unix timestamp
	or current local time if not specified or None,
	use GMT time if gmt is true"""
	if unixtime==None: unixtime=time()
	if gmt: tm=gmtime(unixtime)
	else: tm=localtime(unixtime)
	h,m,s=tm[3:6]
	ts=h*3600+m*60+s
	aml=[2.0/86400.0, 1.0/3600.0, 1.0/60.0]
	for am,f in zip(aml,[self.hf,self.mf,self.sf]):
	    if not f: continue
	    a=2*pi*ts*am
	    f.axis=ax=rotate((0,1,0),angle=-a,axis=(0,0,1))
	    f.up=cross(vector(0,0,1),ax)

def TestClocks():
    scene.title='cx_clock test'
    tl=[('analog',0,0,-pi/6)]
    clk=[]
    for t,x,y,r in tl:
	frm=frame(pos=(x,y,-0.3), axis=(1,0,0), up=rotate((0,1,0),axis=(1,0,0),angle=r), visible=0)
	clk.append(Clock3D(t,frame=frm))
    while 1:
	rate(1)
	for c in clk:
	    c.update()
	    c.frame.visible=1

if __name__=='__main__': TestClocks()