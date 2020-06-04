#version 460 core
#extension GL_NV_gpu_shader_fp64 : enable
#define MAX_STEPS 2000
#define MAX_DIST 5000.
#define SURF_DIST .001
#define PI 3.14159

out vec4 FragColor;

in vec2 fragCoord;

//uniform vec2 arrows;
uniform double ratio;
uniform int stationary;
//uniform mat4 cam_rot;
//uniform mat4 cam_trans;


struct Complex
{
	double re;
	double im;
};

uniform f64vec2 position;
uniform double scale;

Complex complexSquare(Complex c)
{
	Complex ret;
	ret.re = c.re * c.re - c.im * c.im;
	ret.im = 2.0 * c.re * c.im;
	return ret;
}

float inMandel(Complex c, int iterations)
{
	Complex n, next;
	n.re = 0.0;
	n.im = 0.0;
	double nextReS = 0.0;
	double distanceS = 1e20;
	double nextImS = 0.0;
	double nextRe = 0.0;
	double nextIm = 0.0;
	float diters = float(iterations - 1);
	for (int i = 0; i < iterations; i++)
	{
		next.re = nextReS - nextImS + c.re;
		next.im = 2.0*nextRe*nextIm + c.im;
		nextReS = next.re * next.re;
		nextImS = next.im * next.im;
		nextRe = next.re;
		nextIm = next.im;
		double tot = nextReS + nextImS;
		if (tot > 100.0)
		{
			//return float(i) / diters;
			float decimal = log(log(sqrt(float(tot)) / log(2.0f))) / log(2.0f);
			return (float(i) - decimal) / diters;
			//return clamp(sqrt(distanceS),0.0,1.0);
		}
		//distanceS = min(distanceS, tot);
		/*if (abs(nextRe) < 0.0001 && abs(nextIm) < 0.0001 && i > 10)
		{
			i = iterations;
		}*/
	}
	return 1.0;
	//return 10.0 * log2(float(tot)) / pow;
}

double inMandelMarch(Complex c, int iterations)
{
	return 1.0;
}

Complex pixelToComplex(f64vec2 pixelCoord, double ratio)
{
	//f64vec2 position = f64vec2(0.0, 0.0);
	f64vec2 cVec = scale * (pixelCoord);
	cVec.y /= ratio;
	Complex c;
	c.re = cVec.x + position.x;
	c.im = cVec.y + position.y;
	return c;
}

void main()

{
	Complex c = pixelToComplex(f64vec2(fragCoord), ratio);
	int iterations = clamp(stationary, 100, 300);
	float r = inMandel(c, iterations);
	vec3 color = vec3((r-1)*sin(r*30), (1.0f-r)*log(1.0+r), (1.0f-r)*cos(r*2));
	//color = vec3(0.0f, 0.0f, 0.0f);
	FragColor = vec4(color, 1.0f);
}