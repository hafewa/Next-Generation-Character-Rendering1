#pragma once

#define UNITY_PI 3.14159265359f
#define UNITY_INV_PI 0.31830988618f

float3 CalculateNormal(float3 basicNormal, float mask, float _FlattenNormal)
{
    float flatNess = lerp(_FlattenNormal, 1.0, mask);
    float3 scleraNormal = lerp(float4(basicNormal, 1.0), float4(0,0,1,1), flatNess).xyz;

    return scleraNormal;
}

//DFG
float GGXNormalDistributionFunction(float roughness , float nh)
{
    // half a = roughness * roughness;
	// half a2 = a * a;
	// half d = (a2 - 1.0f) * nh * nh + 1.0f;
	// return a2 * UNITY_INV_PI / (d * d + 1e-5f);

    float d = ( nh * roughness - nh ) * nh + 1;	
	return roughness / (UNITY_PI * d * d);		
}

float BeckmanGeometricShadowingFunction(float NdotL, float NdotV, float roughness){

    float roughnessSqr = roughness * roughness;
    float NdotLSqr = NdotL * NdotL;
    float NdotVSqr = NdotV * NdotV;

    float calulationL = (NdotL) / (roughnessSqr * sqrt(1- NdotLSqr));
    float calulationV = (NdotV) / (roughnessSqr * sqrt(1- NdotVSqr));

    float SmithL = calulationL < 1.6 ? (((3.535 * calulationL) + (2.181 * calulationL * calulationL))/(1 + (2.276 * calulationL) + (2.577 * calulationL * calulationL))) : 1.0;
    float SmithV = calulationV < 1.6 ? (((3.535 * calulationV) + (2.181 * calulationV * calulationV))/(1 + (2.276 * calulationV) + (2.577 * calulationV * calulationV))) : 1.0;

	float Gs =  (SmithL * SmithV);
	return Gs;
}

float fresnelReflectance(float3 halfDir, float3 viewDir, float F0)
{
	float base = 1.0 - dot(viewDir, halfDir);
	float exponential = pow(base, 5.0);
	return exponential + F0 * (1.0 - exponential);
}

float3 FresnelEquation(float3 F0 , float vh)
{
    float3 F = F0 + (1 - F0) * exp2((-5.55473 * vh - 6.98316) * vh);
    return F;
}