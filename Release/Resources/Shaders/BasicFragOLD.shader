#version 460 core
#define MAX_STEPS 1000
#define MAX_DIST 800.
#define SURF_DIST .001

out vec4 FragColor;

in vec2 fragCoord;

uniform vec2 res;
uniform mat4 cam_rot;
uniform mat4 cam_trans;

mat4 rotationMatrix(vec3 axis, float angle)

{
	axis = normalize(axis);
	float s = sin(angle);
	float c = cos(angle);
	float oc = 1.0 - c;

	return mat4(oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s, oc * axis.z * axis.x + axis.y * s, 0.0,
		oc * axis.x * axis.y + axis.z * s, oc * axis.y * axis.y + c, oc * axis.y * axis.z - axis.x * s, 0.0,
		oc * axis.z * axis.x - axis.y * s, oc * axis.y * axis.z + axis.x * s, oc * axis.z * axis.z + c, 0.0,
		0.0, 0.0, 0.0, 1.0);
}

float sphere(vec3 p, vec4 n)

{
	return length(p - n.xyz) - n.w;
}

float plane(vec3 p, vec4 n)

{
	return dot(p, n.xyz) + n.w;
}

float GetDist(vec3 p)

{
	//p = z;
	float s;
	float d = plane(p, vec4(0, 1, 0, 0));
	vec3 n1 = normalize(vec3(1, 1, 0));
	vec3 n2 = normalize(vec3(1, 0, 1));

	p -= 2.0*min(0.0, dot(p, n2))*n2;
	p -= 2.0*min(0.0, dot(p, n1))*n1;
	p.xyz = mod(p.xyz, vec3(4.0, 20.0, 2.0));
	s = sphere(p, vec4(2.0, 10.0, 1.0, 1.0));

	

	return min(s,d);
	
}

vec3 RayMarch(vec3 ro, vec3 rd)

{
	float dO = 0.;
	float breakout = -1.0;
	float minDist = 10.;

	for (int i = 0; i < MAX_STEPS; i++)

	{
		vec3 p = ro + rd * dO;
		float ds = GetDist(p);
		dO += ds;
		
		minDist = min(minDist, ds);

		if (ds < SURF_DIST)

		{
			breakout = i;
			break;
		}

		if (dO > MAX_DIST)

		{
			breakout = MAX_STEPS;
			break;
		}
	}

	if (breakout < 0.0) breakout = MAX_STEPS;

	return vec3(dO, breakout, minDist);
}


float RayMarchShadow(vec3 ro, vec3 rd, float length)

{
	float res = 1.0;
	//float dO = SURF_DIST;

	for (float dO = SURF_DIST; dO < length;)

	{
		vec3 p = ro + rd * dO;
		float ds = GetDist(p);
		dO += ds;

		if (ds < SURF_DIST)

		{
			res = 0.1;
			return res;
		}

		res = min(res, 100 * ds / dO);
	}

	res = clamp(res, 0.1, 1.0);

	return res;
}

vec3 GetNormal(vec3 p)

{
	float d = GetDist(p);
	vec2 e = vec2(SURF_DIST*2, 0);

	vec3 n = d - vec3(
		GetDist(p - e.xyy),
		GetDist(p - e.yxy),
		GetDist(p - e.yyx));
	return normalize(n);
}

float GetLight(vec3 p, float surfCom, vec3 lightPos)

{
	//lightPos = vec3(1, 30, 1);
	vec3 l = normalize(lightPos - p);
	vec3 n = GetNormal(p);
	float dif = clamp(dot(n, l), 0.01, 1.);
	float occDark = 1.0;
	//0.98 for non normal
	if (surfCom > 5) occDark = pow(0.98, surfCom - 6);
	
	dif *= clamp(occDark, 0.01, 1.0);


	//vec3 d = RayMarch(p + n * SURF_DIST*2., l);
	dif *= RayMarchShadow(p + n * SURF_DIST*3.0, l, length(lightPos - p));

	//if (d.x < length(lightPos - p)) dif *= 0.1;
	//if (d.z < 0.1) dif *= (d.z- 0.1)*2 + 1.0;


	return dif;
}

void main()

{
	float ratio = res.x / res.y;
	vec2 uv = vec2(fragCoord.x, fragCoord.y / ratio);

	vec3 col = vec3(0);
	
	vec3 ro = (cam_trans*vec4(0, 1.0, 0, 1.0)).xyz;
	//vec3 rd = normalize(vec3(uv.x, uv.y - 0.3, 1));
	vec4 cam = cam_rot * vec4(uv.x, uv.y, 1.0, 1.0);
	vec3 rd = normalize(cam.xyz);

	vec3 d = RayMarch(ro, rd);

	vec3 p = ro + rd * d.x;

	float dif = GetLight(p, d.y, vec3(2., 30.0, 2.0));
	dif += GetLight(p, d.y, vec3(100.0, 20.0, 0.0));

	dif /= 2.0;

	//dif = clamp(dif, 0.0, 1.0);

	//vec3 n = GetNormal(p);

	//vec3 hue = normalize(vec3(0.29, 0.9, 0.48));

	col = vec3(dif);

	if (d.y > MAX_STEPS - 1)

	{
		//col = normalize(hue + 1.2);
	}

	col = GetNormal(p)*dif;
	FragColor = vec4(col, 1.0f);
}