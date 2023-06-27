varying vec2 vUvs;
uniform vec2 resolution;
uniform float time;

float SEED = 3.95; //Keep it under 10 000 to avoid weird float glitches DEFAULT = 3.95
float TEMPERATURE = 0.0; //between -1 and 1, DEFAULT = 0.0
float BIOMASS = 0.5;//between 0 and 1 DEFAULT = 0.5
float WATERLEVEL = 1.0; //DEFAULT = 1.0
float OZONE = 1.0; //DEFAULT = 1.0
float PLANETSIZE = 400.0; //DEFAULT = 400
float ROTATION = 0.25; //DEFAULT = 0.25
vec3 SUNLIGHT = vec3(1.0,1.0,1.0); //DEFAULT = vec3(1.0,1.0,1.0)
vec3 SUNPOSITION = vec3(0.6, 0.2, 0.5); //DEFAULT = vec3(0.6, 0.2, 0.5);

float CONTINENTS = 2.0; //experimental...

// Simplex noise function taken from : https://github.com/ashima/webgl-noise
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License.
// Includes these functions : mod289, permute, taylorInvSqrt, snoise
vec3 mod289(vec3 x)
{
    return x - floor(x / 289.0) * 289.0;
}

vec4 mod289(vec4 x)
{
    return x - floor(x / 289.0) * 289.0;
}

vec4 permute(vec4 x)
{
    return mod289((x * 34.0 + 1.0) * x);
}

vec4 taylorInvSqrt(vec4 r)
{
    return 1.79284291400159 - r * 0.85373472095314;
}

vec4 snoise(vec3 v)
{
    const vec2 C = vec2(1.0 / 6.0, 1.0 / 3.0);

    // First corner
    vec3 i  = floor(v + dot(v, vec3(C.y)));
    vec3 x0 = v   - i + dot(i, vec3(C.x));

    // Other corners
    vec3 g = step(x0.yzx, x0.xyz);
    vec3 l = 1.0 - g;
    vec3 i1 = min(g.xyz, l.zxy);
    vec3 i2 = max(g.xyz, l.zxy);

    vec3 x1 = x0 - i1 + C.x;
    vec3 x2 = x0 - i2 + C.y;
    vec3 x3 = x0 - 0.5;

    // Permutations
    i = mod289(i); // Avoid truncation effects in permutation
    vec4 p =
      permute(permute(permute(i.z + vec4(0.0, i1.z, i2.z, 1.0))
                            + i.y + vec4(0.0, i1.y, i2.y, 1.0))
                            + i.x + vec4(0.0, i1.x, i2.x, 1.0));

    // Gradients: 7x7 points over a square, mapped onto an octahedron.
    // The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
    vec4 j = p - 49.0 * floor(p / 49.0);  // mod(p,7*7)

    vec4 x_ = floor(j / 7.0);
    vec4 y_ = floor(j - 7.0 * x_); 

    vec4 x = (x_ * 2.0 + 0.5) / 7.0 - 1.0;
    vec4 y = (y_ * 2.0 + 0.5) / 7.0 - 1.0;

    vec4 h = 1.0 - abs(x) - abs(y);

    vec4 b0 = vec4(x.xy, y.xy);
    vec4 b1 = vec4(x.zw, y.zw);

    vec4 s0 = floor(b0) * 2.0 + 1.0;
    vec4 s1 = floor(b1) * 2.0 + 1.0;
    vec4 sh = -step(h, vec4(0.0));

    vec4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
    vec4 a1 = b1.xzyw + s1.xzyw * sh.zzww;

    vec3 g0 = vec3(a0.xy, h.x);
    vec3 g1 = vec3(a0.zw, h.y);
    vec3 g2 = vec3(a1.xy, h.z);
    vec3 g3 = vec3(a1.zw, h.w);

    // Normalize gradients
    vec4 norm = taylorInvSqrt(vec4(dot(g0, g0), dot(g1, g1), dot(g2, g2), dot(g3, g3)));
    g0 *= norm.x;
    g1 *= norm.y;
    g2 *= norm.z;
    g3 *= norm.w;

    // Compute noise and gradient at P
    vec4 m = max(0.6 - vec4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
    vec4 m2 = m * m;
    vec4 m3 = m2 * m;
    vec4 m4 = m2 * m2;
    vec3 grad =
      -6.0 * m3.x * x0 * dot(x0, g0) + m4.x * g0 +
      -6.0 * m3.y * x1 * dot(x1, g1) + m4.y * g1 +
      -6.0 * m3.z * x2 * dot(x2, g2) + m4.z * g2 +
      -6.0 * m3.w * x3 * dot(x3, g3) + m4.w * g3;
    vec4 px = vec4(dot(x0, g0), dot(x1, g1), dot(x2, g2), dot(x3, g3));
    return 42.0 * vec4(grad, dot(m4, px));
}

//FBM function inspired at first by : https://thebookofshaders.com/13/
//But has been modified according to my needs. FBM functions usually have this format.
float fbm(vec3 p, float amplitude, float frequency, int octaves, float lacunarity, float gain, float e)
{
  float fbmValue = 0.0;

  for (int i = 0; i < octaves; i++) 
  {
    fbmValue += amplitude * snoise(p * frequency + SEED ).w;;
    frequency *= lacunarity;
    amplitude *= gain;
  }

  return pow(fbmValue/4.0 + 0.5, e);
}

float circleSDF(vec2 p, float r)
{
  return length(p) - r;
}

float fbmDifference(vec3 pos, vec3 e) 
{
  return fbm(pos + e, 1.0, 1.0, 6, 2.0, 0.5, 4.0) - fbm(pos - e, 1.0, 1.0, 6, 2.0, 0.5, 4.0); 
}

vec3 normalNoise(vec3 pos, vec3 n, float noiseAtCoord) 
{
  vec2 variation = vec2(0.01, 0.0); //wrinkle amount

  vec3 noisedPosition = vec3(
          fbmDifference(pos, variation.xyy),
          fbmDifference(pos, variation.yxy),
          fbmDifference(pos, variation.yyx)
      );

  vec3 waterNormals = normalize(n + -1.2 * noisedPosition);
  vec3 landNormals = normalize(n + -6.0 * noisedPosition);
  vec3 mountainNormals = normalize(n + -10.0 * noisedPosition);

  vec3 normal = mix(
      waterNormals,
      landNormals,
      smoothstep(0.05, 0.06, noiseAtCoord));
  normal = mix(
      normal,
      mountainNormals,
      smoothstep(0.1, 0.2, noiseAtCoord));

  return normal;
}

mat3 rotate(float radians) //rotate y
{ 
  float s = sin(radians);
  float c = cos(radians);
  return mat3(
      c, 0.0, s,
      0.0, 1.0, 0.0,
      -s, 0.0, c);
}

//Phong at first taken from my previous project here : https://github.com/AlexandreMarquesDias/GLSL-light-reflection-models
//But has been very heavily modified according to my needs
vec3 phong(float noiseAtCoord, vec3 n, vec3 planet)
{
  vec3 lightDir = normalize(SUNPOSITION);
 
  float ambient = 0.022;
  float diffuse = max(dot(lightDir, n), 0.0);
  float diffuseTweak = mix(0.2,0.8,smoothstep(0.04, 0.45, diffuse)); //give smoother transition night/day
  float phongShade =  ambient + diffuse * diffuseTweak;
  
  vec3 r = normalize(reflect(-lightDir, n));
  vec3 v = normalize(vec3(0.0, 0.0, 1.0));
  float waterspec = mix(0.5,0.05,smoothstep(0.05*WATERLEVEL, 0.06*WATERLEVEL, noiseAtCoord)); //only water is specular
  float specular = pow(max(dot(r, v), 0.0),20.0) * waterspec * 1.4;
  
  float lightIntensity = 2.0;

  return planet * lightIntensity * phongShade*SUNLIGHT + specular*SUNLIGHT;
}

vec3 generatePlanet(vec2 pixelCoords) 
{
  float d = circleSDF(pixelCoords, PLANETSIZE); 
  vec3 planet = vec3(1.0);
  if(d <= 0.0)
  {
    float x = pixelCoords.x / PLANETSIZE;
    float y = pixelCoords.y / PLANETSIZE;
    float z = sqrt(1.0-x*x-y*y);

    vec3 worldPosition = vec3(x, y, z);
    mat3 rotation = rotate(time * ROTATION);
    vec3 coordinate = rotation * worldPosition * CONTINENTS;

    float noiseAtCoord = fbm(coordinate, 1.0, 0.6, 6, 2.0, 0.5, 4.0);
    float desertMap = fbm(coordinate * (1.0-BIOMASS)+ vec3(20.0),1.0, 0.6, 2, 2.0, 0.5, 0.8);

    vec3 land = mix(
      vec3(0.439,0.557,0.624),
      vec3(0.224*(1.0-BIOMASS)*2.0,0.396,0.435*(1.0-BIOMASS)*2.0),
      smoothstep(0.05, 0.1, noiseAtCoord));

    land = mix(vec3(0.729,0.635,0.416),land, smoothstep(0.7-BIOMASS,1.2-BIOMASS,desertMap)); //add desert 
    land = mix(land,vec3(0.45), smoothstep(0.1, 0.2,noiseAtCoord)); //add gray mountains
    land = mix(land,vec3(0.9), smoothstep(0.6+TEMPERATURE,0.9+TEMPERATURE,abs(worldPosition.y))); //add snow to poles

    vec3 water = mix(
      vec3(0.094,0.165,0.459),
      vec3(0.196,0.592,0.647),
      smoothstep(0.02*(1.0/WATERLEVEL), 0.08*WATERLEVEL, noiseAtCoord));
    water =mix(water,vec3(0.6,0.75,1.0), smoothstep(0.80+TEMPERATURE,0.92+TEMPERATURE,abs(worldPosition.y))); //add ice to poles

    planet = mix(water, land, smoothstep(0.05, 0.06, noiseAtCoord*(1.0/WATERLEVEL))); //mix land and water

    vec3 surfaceNormal = normalNoise(coordinate, normalize(worldPosition), noiseAtCoord); //procedural bump map
    planet = phong(noiseAtCoord, surfaceNormal, planet);

    float ozone = smoothstep(1.0, 0.1*OZONE, worldPosition.z);
    ozone = pow(ozone, 3.0) * max(dot(normalize(vec3(0.6, 0.2, 0.5)), worldPosition), 0.1);
    planet = mix(planet, vec3(0.353*OZONE,0.596*OZONE,0.82*OZONE), ozone);

    return planet;
  }
  return vec3(0.0);
}

void main() 
{
  vec2 pixelCoords = (vUvs - 0.5) * resolution;
  vec3 pixelColor = generatePlanet(pixelCoords);
  gl_FragColor = vec4(pixelColor, 1.0);
}