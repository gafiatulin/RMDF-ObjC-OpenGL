#version 410 core

uniform vec2 resolution;
uniform float globalTime;
uniform vec3 camPosition;
uniform vec3 camDirection;
uniform vec3 camRight;
vec3 camUp = cross(camRight, camDirection);
#define FOCAL_LENGTH 2.0
//#define START_HEIGHT 200.0
#define START_HEIGHT 50.0
vec3 sunLight  = normalize( vec3(  0.35, 0.1,  0.3 ) );
const vec3 sunColour = vec3(1.0, .75, .5);
//----------------------------------------------------------------------

out vec4 outColor;

//----------------------------------------------------------------------
//Distance Functions
float sdPlane(vec3 p) { return p.y; }
float sdSphere(vec3 p, float r) {return length(p) - r;}
float sdBox(vec3 p, vec3 b)
{
  vec3 d = abs(p) - b;
  return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}
float udRoundBox(vec3 p, vec3 b, float r) {return length(max(abs(p) - b, 0.0)) - r;}
float sdTorus(vec3 p, vec2 t)
{
  vec2 q = vec2(length(p.xz) - t.x, p.y);
  return length(q) - t.y;
}
float sdHexPrism(vec3 p, vec2 h)
{
  vec3 q = abs(p);
  return max(q.z - h.y, max(q.x + q.y * 0.57735, q.y * 1.1547) - h.x);
}
float sdCapsule(vec3 p, vec3 a, vec3 b, float r)
{
  vec3 pa = p - a;
  vec3 ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  return length(pa - ba * h) - r;
}
float sdTriPrism(vec3 p, vec2 h)
{
  vec3 q = abs(p);
  return max(q.z - h.y, max(q.x * 0.866025 + p.y * 0.5, -p.y) - h.x * 0.5);
}
float sdCylinder(vec3 p, vec2 h)
{
  return max(length(p.xz) - h.x, abs(p.y) - h.y);
}
float sdCone(in vec3 p, in vec3 c)
{
  vec2 q = vec2(length(p.xz), p.y);
  return max(max(dot(q, c.xy), p.y), -p.y - c.z);
}
//----------------------------------------------------------------------
/*float simpleHash(float n) { return fract(sin(n) * 43758.5453123);}

vec3 simpleNoise(in vec2 x)
{
  x+=4.2;
  vec2 p = floor(x);
  vec2 f = fract(x);
  vec2 u = f*f*(3.0-2.0*f);
	//vec2 u = f*f*f*(6.0*f*f - 15.0*f + 10.0);
  float n = p.x + p.y*57.0;
  float a = simpleHash(n + 0.0);
  float b = simpleHash(n + 1.0);
  float c = simpleHash(n + 57.0);
  float d = simpleHash(n + 58.0);
	return vec3(a+(b-a)*u.x+(c-a)*u.y+(a-b-c+d)*u.x*u.y,30.0*f*f*(f*(f-2.0)+1.0)*(vec2(b-a,c-a)+(a-b-c+d)*u.yx));
}

//const mat2 rotate2D = mat2(1.732, 1.323, -1.523, 1.652);

float terrain( in vec2 p)
{
	vec2 pos = p*0.001;
	float w = START_HEIGHT;
	float f = 0.0;
	vec2  d = vec2(0.0);
	for (int i = 0; i < 6; i++)
	{
    vec3 n = simpleNoise(pos);
    d += n.yz;
    f += w * n.x/(1.0+dot(d,d));
		w = w * 0.53;
		pos = rotate2D * pos;
	}
	return f;
}

/*
void FAST_hash_2D( vec2 gridcell, out vec4 hash_0, out vec4 hash_1 )
{
  const vec2 OFFSET = vec2( 26.0, 161.0 );
  const float DOMAIN = 71.0;
  const vec2 LARGEFLOATS = vec2( 951.135664, 642.949883 );
  vec4 P = vec4( gridcell.xy, gridcell.xy + 1.0 );
  P = P - floor(P * ( 1.0 / DOMAIN )) * DOMAIN;
  P += OFFSET.xyxy;
  P *= P;
  P = P.xzxz * P.yyww;
  hash_0 = fract( P * ( 1.0 / LARGEFLOATS.x ) );
  hash_1 = fract( P * ( 1.0 / LARGEFLOATS.y ) );
}

float SimplexPerlin2D( vec2 P )
{
  const float SKEWFACTOR = 0.36602540378443864676372317075294;
  const float UNSKEWFACTOR = 0.21132486540518711774542560974902;
  const float SIMPLEX_TRI_HEIGHT = 0.70710678118654752440084436210485;
  const vec3 SIMPLEX_POINTS = vec3( 1.0-UNSKEWFACTOR, -UNSKEWFACTOR, 1.0-2.0*UNSKEWFACTOR );
  P *= SIMPLEX_TRI_HEIGHT;
  vec2 Pi = floor( P + dot( P, vec2( SKEWFACTOR ) ) );
  vec4 hash_x, hash_y;
  FAST_hash_2D( Pi, hash_x, hash_y );
  vec2 v0 = Pi - dot( Pi, vec2( UNSKEWFACTOR ) ) - P;
  vec4 v1pos_v1hash = (v0.x < v0.y) ? vec4(SIMPLEX_POINTS.xy, hash_x.y, hash_y.y) : vec4(SIMPLEX_POINTS.yx, hash_x.z, hash_y.z);
  vec4 v12 = vec4( v1pos_v1hash.xy, SIMPLEX_POINTS.zz ) + v0.xyxy;
  vec3 grad_x = vec3( hash_x.x, v1pos_v1hash.z, hash_x.w ) - 0.49999;
  vec3 grad_y = vec3( hash_y.x, v1pos_v1hash.w, hash_y.w ) - 0.49999;
  vec3 grad_results = inversesqrt( grad_x * grad_x + grad_y * grad_y ) * ( grad_x * vec3( v0.x, v12.xz ) + grad_y * vec3( v0.y, v12.yw ) );
  const float FINAL_NORMALIZATION = 99.204334582718712976990005025589;
  vec3 m = vec3( v0.x, v12.xz ) * vec3( v0.x, v12.xz ) + vec3( v0.y, v12.yw ) * vec3( v0.y, v12.yw );
  m = max(0.5 - m, 0.0);//0.5 == SIMPLEX_TRI_HEIGHT^2
  m = m*m;
  return dot(m*m, grad_results) * FINAL_NORMALIZATION;
}
*/


//----------------------------------------------------------------------
//Distance Operations
float opUnion( float d1, float d2 ){return min(d1, d2);}
float opSubstraction(float d1, float d2) { return max(-d2, d1); }
float opIntersection( float d1, float d2 ){return max(d1,d2);}
vec3 opRepetition(vec3 p, vec3 c) { return mod(p, c) - 0.5 * c; }
vec3 opAffineTransformation(vec3 p, mat4 transform){return (inverse(transform)*vec4(p, 1.0)).xyz;}
vec3 opTranslation(vec3 p, vec3 tr) {return p-tr;} //convinience for affine transform
//float opDisplace(vec3 p, float d){return d+displacement(p);} //Need displacement function
float opBlend(float d1, float d2, float k){ //k = 0.1
  float h = clamp( 0.5+0.5*(d2-d1)/k, 0.0, 1.0 );
  return mix( d2, d1, h ) - k*h*(1.0-h);
}
//----------------------------------------------------------------------
/*float map(in vec3 pos)
{
  /*float res = sdPlane(pos);
  res = opUnion(res, sdSphere(pos-vec3( 0.0, 0.25, 0.0), 0.25));
  res = opUnion(res, sdBox(pos-vec3( 1.0,0.25, 0.0), vec3(0.25)));
  res = opUnion(res, sdTorus(pos-vec3( 0.0,0.25, 1.0), vec2(0.20,0.05)));
  res = opUnion(res, sdTriPrism(pos-vec3( 1.0,0.25, 1.0), vec2(0.25,0.05)));
  res = opUnion(res, sdCylinder(pos-vec3( 1.0,0.30,-1.0), vec2(0.1,0.2)));
  res = opUnion(res, sdCone(pos-vec3( 0.0,0.50,-1.0), vec3(0.8,0.6,0.3)));
  res = opUnion(res, opSubstraction(sdBox(pos-vec3(-1.0,0.25,-1.0), vec3(0.25)), sdSphere(pos-vec3(-1.0,0.25,-1.0), 0.32)));
  res = opUnion(res, opUnion(sdBox(pos-vec3(-1.0,0.25, 0.0), vec3(0.25)), sdSphere(pos-vec3(-1.0,0.25,0.0), 0.32)));
  res = opUnion(res, opIntersection(sdBox(pos-vec3(-1.0,0.25, 1.0), vec3(0.25)), sdSphere(pos-vec3(-1.0,0.25,1.0), 0.32)));
  return res;
  return pos.y - terrain(pos.xz);
  //return opBlend(pos.y - terrain(pos.xz), sdBox(pos-vec3(0.0, terrain(vec2(0.0)) ,0.0), vec3(50, 250, 50)), 2.0);
  //return opUnion(pos.y - terrain(pos.xz), sdBox(pos-vec3(0.0, 2.0, 0.0), vec3(50.0)));
}*/
/*
float castRay(in vec3 ro, in vec3 rd)
{
  float h = 1.0;
  float t = 1.0;
  for (int i = 0; i < 128; i++)
  {
    if (h < 0.001 || t > 2000.0) break;
    t += 0.5 * h * (1.0 + 0.0002 * t);
    h = map(ro + t * rd);
  }
  if (h > 10.0)
    t = -1.0;
  return t;
}

float softshadow(in vec3 ro, in vec3 rd)
{
  float res = 1.0;
  float t = 0.0;
  for (int j = 0; j < 128; j++)
  {
    float h = map(ro + t * rd);
    res = min(res, 8.0 * h / t);
    t += h;
  }
  return clamp(res, 0.0, 1.0);
}
*/
/*
vec3 calcNormal(in vec3 pos)
{
  vec3 eps = vec3(0.01, 0.0, 0.0);
  vec3 nor = vec3(map(pos + eps.xyy) - map(pos - eps.xyy),
                  map(pos + eps.yxy) - map(pos - eps.yxy),
                  map(pos + eps.yyx) - map(pos - eps.yyx));
  return normalize(nor);
}*/

vec3 sky(vec3 rd, vec3 sunLight)
{
  float atmos = smoothstep(0.0, 1.0, (clamp(sunLight.y, 0.0, 1.0)))*pow((1.0-rd.y),4.0)*(dot(rd,sunLight)*0.2+0.2);
  float atmos2 = ((sunLight.y*0.5)*pow((2.0-rd.y), 1.5));
  vec3 atmosc; atmosc.r = atmos*0.2;
  atmosc.g=atmosc.r-0.5;atmosc.b=atmosc.g-0.3;
  atmosc = clamp(vec3(0.0),atmosc,vec3(2.0));
  vec3 atmos2c; atmos2c.b = atmos2*0.5;
  atmos2c.g=atmos2c.b-0.2;atmos2c.r=atmos2c.g-0.2;
  atmos2c = clamp(vec3(0.0),atmos2c,vec3(2.0));
  vec3 final = atmosc*0.5+atmos2c;
  final += vec3(0.1,0.13,0.2);
  return clamp(final, 0.0, 1.0);
}

/*vec3 render(in vec3 ro, in vec3 rd)
{
  //Sky
  //vec3 sunLight  = normalize( vec3(  0.35, 0.1,  0.3 ) );
  const vec3 sunColour = vec3(1.0, .75, .5);

  vec3 sunLight = normalize(vec3(sin(0.5*globalTime), 1.3 , cos(0.5*globalTime)));
  vec3 sky = sky(rd, sunLight) + vec3(pow((1.0+dot(rd,sunLight))*0.5,127.0));
  //Base Color
  vec3 scene = vec3(1.0, 1.0, 1.0);
  //Cast Ray
  float t = castRay(ro, rd);
  vec3 pos = ro + t * rd;
  vec3 nor = calcNormal(pos);
  //Lighting
  float ambientLight = clamp(0.5 + 0.5 * nor.y, 0.0, 1.0);
  float LightLevel = clamp(dot(nor, sunLight), 0.0, 1.0);
  float bac = clamp(dot(nor, normalize(vec3(-sunLight.x, 0.0, -sunLight.z))), 0.0, 1.0) * clamp(1.0 - pos.y, 0.0, 1.0);
  float sh = 1.0;
  //Soft Shadows
  //if (LightLevel > 0.02){LightLevel *= softshadow(pos, sunLight);}
  //Shading
  vec3 brdf = vec3(0.0);
  brdf += 0.20 * ambientLight * vec3(0.10, 0.11, 0.13);
  brdf += 0.20 * bac * vec3(0.15, 0.15, 0.15);
  brdf += 1.20 * LightLevel * vec3(1.00, 0.90, 0.70);
  float pp = clamp(dot(reflect(rd, nor), sunLight), 0.0, 1.0);
  float spec = pow(pp, 16.0);
  float fre = pow(clamp(1.0 + dot(nor, rd), 0.0, 1.0), 2.0);//* ao;
  scene = (scene * brdf )+ vec3(0.1) * scene * spec + 0.2 * fre * (0.5 + 0.5 * scene);
  vec3 col = int(t < 0.0)*sky + int(t > 0.0)*scene;
  return clamp(col, 0.0, 1.0);
}*/

vec3 PostEffects(vec3 rgb, vec2 xy)
{
  // Gamma first...
  rgb = pow(rgb, vec3(0.45));
  
  // Then...
#define CONTRAST 1.2
#define SATURATION 1.3
#define BRIGHTNESS 1.4
  rgb = mix(vec3(.5), mix(vec3(dot(vec3(.2125, .7154, .0721), rgb*BRIGHTNESS)), rgb*BRIGHTNESS, SATURATION), CONTRAST);
  // Noise...
  // rgb = clamp(rgb+Hash(xy*iGlobalTime)*.1, 0.0, 1.0);
  // Vignette...
  rgb *= .4+0.5*pow(40.0*xy.x*xy.y*(1.0-xy.x)*(1.0-xy.y), 0.2 );
  
  return rgb;
}

float Hash( float n )
{
  return fract(sin(n)*33753.545383);
}
float Linstep(float a, float b, float t)
{
  return clamp((t-a)/(b-a),0.,1.);
  
}

const mat2 rotate2D = mat2(1.732, 1.323, -1.523, 1.652);
//--------------------------------------------------------------------------
vec3 NoiseD( in vec2 x )
{
  vec2 p = floor(x);
  vec2 f = fract(x);
  
  vec2 u = f*f*(3.0-2.0*f);
  //vec2 u = f*f*f*(6.0*f*f - 15.0*f + 10.0);
  float n = p.x + p.y*57.0;
  
  float a = Hash(n+  0.0);
  float b = Hash(n+  1.0);
  float c = Hash(n+ 57.0);
  float d = Hash(n+ 58.0);
  return vec3(a+(b-a)*u.x+(c-a)*u.y+(a-b-c+d)*u.x*u.y,
              30.0*f*f*(f*(f-2.0)+1.0)*(vec2(b-a,c-a)+(a-b-c+d)*u.yx));
}

//--------------------------------------------------------------------------
float Terrain( in vec2 p)
{
  vec2 pos = p*0.0035;
  float w = START_HEIGHT;
  float f = .0;
  vec2  d = vec2(0.0);
  for (int i = 0; i < 5; i++)
  {
    //f += Noise(pos) * w;
    vec3 n = NoiseD(pos);
    d += n.yz;
    f += w * n.x/(1.0+dot(d,d));
    w = w * 0.53;
    pos = rotate2D * pos;
  }
  
  return f;
}

//--------------------------------------------------------------------------
float Terrain2( in vec2 p, in float sphereR)
{
  vec2 pos = p*0.0035;
  float w = START_HEIGHT;
  float f = .0;
  vec2  d = vec2(0.0);
  // Set a limit to the loop as further away terrain doesn't need fine detail.
  int t = 11-int(sphereR);
  if (t < 5) t = 5;
  
  for (int i = 0; i < 9; i++)
  {
    if (i > t) continue;
    vec3 n = NoiseD(pos);
    d += n.yz;
    f += w * n.x/(1.0+dot(d,d));
    w = w * 0.53;
    pos = rotate2D * pos;
  }
  
  return f;
}

float pyramids(in vec3 p)
{
  vec3 q = opRepetition(p, vec3(2341, 0, 2937));
  float g = sdBox(q, vec3(200, 50, 200));
  g = opUnion(g, sdBox(q, vec3(150, 100, 150)));
  g = opUnion(g, sdBox(q, vec3(100, 150, 100)));
  g = opUnion(g, sdBox(q, vec3(50, 200, 50)));
  return g;
}

//--------------------------------------------------------------------------
float Map(in vec3 p)
{
  float h = Terrain(p.xz);
  float f = p.y - h;
  float g = pyramids(p);
  return opUnion(f, g);
}

//--------------------------------------------------------------------------
// Grab all sky information for a given ray from camera
vec3 GetSky(in vec3 rd)
{
  float sunAmount = max( dot( rd, sunLight), 0.0 );
  float v = pow(1.0-max(rd.y,0.0),6.);
  vec3  sky = mix(vec3(.015,0.0,.01), vec3(.42, .2, .1), v);
  //sky *= smoothstep(-0.3, .0, rd.y);
  sky = sky + sunColour * sunAmount * sunAmount * .25;
  sky = sky + sunColour * min(pow(sunAmount, 800.0)*1.5, .3);
  return clamp(sky, 0.0, 1.0);
}

//--------------------------------------------------------------------------
float SphereRadius(float t)
{
  t = abs(t-100.0);
  t *= 0.009;
  return clamp(t*t, 50.0/resolution.y, 80.0);
}

//--------------------------------------------------------------------------
// Calculate sun light...
vec3 DoLighting(in vec3 mat, in vec3 normal, in vec3 eyeDir)
{
  float h = dot(sunLight,normal);
  mat = mat * sunColour*(max(h, 0.0));
  mat += vec3(0.04, .02,.02) * max(normal.y, 0.0);
  return mat;
}

//--------------------------------------------------------------------------
vec3 GetNormal(vec3 p, float sphereR)
{
  vec2 j = vec2(sphereR, 0.0);
  vec3 nor  	= vec3(0.0,		Terrain2(p.xz, sphereR), 0.0);
  vec3 v2		= nor-vec3(j.x,	Terrain2(p.xz+j, sphereR), 0.0);
  vec3 v3		= nor-vec3(0.0,	Terrain2(p.xz-j.yx, sphereR), -j.x);
  nor = cross(v2, v3);
  return normalize(nor);
}

vec4 Scene(in vec3 rO, in vec3 rD, out vec3 p)
{
  float t = 0.0;
  float alpha;
  vec4 normal = vec4(0.0);
  float oldT = 0.0;
  for( int j=0; j < 105; j++ )
  {
    if (normal.w >= .8 || t > 1400.0) break;
    p = rO + t*rD;
    float sphereR = SphereRadius(t);
    float h = Map(p);
    if( h < sphereR)
    {
      // Accumulate the normals...
      //vec3 nor = GetNormal(rO + BinarySubdivision(rO, rD, t, oldT, sphereR) * rD, sphereR);
      vec3 nor = GetNormal(p, sphereR);
      alpha = (1.0 - normal.w) * ((sphereR-h) / sphereR);
      normal += vec4(nor * alpha, alpha);
    }
    oldT = t;
    t +=  h*.6 + t * .002;
  }
  normal.xyz = normalize(normal.xyz);
  // Scale the alpha up to 1.0...
  normal.w = clamp(normal.w * (1.0 / .8), 0.0, 1.0);
  // Fog...   :)
  normal.w /= 1.0+(smoothstep(300.0, 1400.0, t) * 2.0);
  return normal;
}

void main(void)
{
  vec2 xy = gl_FragCoord.xy / resolution.xy;
  vec2 uv = (-1.0 + 2.0 * (gl_FragCoord.xy / resolution.xy)) * vec2(resolution.x / resolution.y, 1);
  vec3 cp = vec3(camPosition.x, max(Terrain(camPosition.xz)+15, camPosition.y), camPosition.z);
  vec3 ro = cp;//camPosition;
  vec3 dir = normalize(camDirection * FOCAL_LENGTH + camRight * uv.x + camUp * uv.y);
  vec3 col;
  float distance;
  vec4 normal;
  vec3 p = vec3(0.0);
  normal = Scene(ro, dir, p);
  if(pyramids(p) < 5)
    col = vec3(0.5);
  else
  {
    col = mix(vec3(.4, 0.4, 0.3), vec3(.7, .35, .1),smoothstep(0.8, 1.1, (normal.y)));
    col = mix(col, vec3(0.17, 0.05, 0.0), clamp(normal.z+.2, 0.0, 1.0));
    col = mix(col, vec3(.8, .8,.5), clamp((normal.x-.6)*1.3, 0.0, 1.0));
  }
  
  if (normal.w > 0.0) col = DoLighting(col, normal.xyz, dir);
  
  col = mix(GetSky(dir), col, normal.w);
  
  vec3 cw = dir;//normalize(camTar-cameraPos);
  //vec3 cp = camUp;//vec3(sin(roll), cos(roll),0.0);
  vec3 cu = camUp;//cross(cw,cp);
  vec3 cv = camRight;//cross(cu,cw);
  //vec3 dir = normalize(uv.x*cu + uv.y*cv + 1.1*cw);
  mat3 camMat = mat3(cu, cv, cw);
  // bri is the brightness of sun at the centre of the camera direction.
  // Yeah, the lens flares is not exactly subtle, but it was good fun making it.
  float bri = dot(cw, sunLight)*.7;
  if (bri > 0.0)
  {
    vec2 sunPos = vec2( dot( sunLight, cu ), dot( sunLight, cv ) );
    vec2 uvT = uv-sunPos;
    uvT = uvT*(length(uvT));
    bri = pow(bri, 6.0)*.8;
    
    // glare = the red shifted blob...
    float glare1 = max(dot(normalize(vec3(dir.x, dir.y+.3, dir.z)),sunLight),0.0)*1.4;
    // glare2 is the yellow ring...
    float glare2 = max(1.0-length(uvT+sunPos*.5)*4.0, 0.0);
    uvT = mix (uvT, uv, -2.3);
    // glare3 is a purple splodge...
    float glare3 = max(1.0-length(uvT+sunPos*5.0)*1.2, 0.0);
    
    col += bri * vec3(1.0, .0, .0)  * pow(glare1, 12.5)*.05;
    col += bri * vec3(1.0, .5, 0.5) * pow(glare2, 2.0)*2.5;
    col += bri * sunColour * pow(glare3, 2.0)*3.0;
  }
  col = PostEffects(col, xy);
  outColor = vec4(col, 1.0);
}