#pragma once
#include "Structure.hlsl"
#include "Lighting.hlsl"
#include "PBRFunction.hlsl"

#define UNITY_PI 3.14159265359f

TEXTURE2D(_IrisNormalTex);    
float4 _IrisNormalTex_ST;
SAMPLER(sampler_IrisNormalTex);

TEXTURE2D(_IrisTexture);    
float4 _IrisTexture_ST;
SAMPLER(sampler_IrisTexture);

TEXTURE2D(_ScleraTexture);    
float4 _ScleraTexture_ST;
SAMPLER(sampler_ScleraTexture);

TEXTURE2D(_IrisPlaneDstTexture);    
float4 _IrisPlaneDstTexture_ST;
SAMPLER(sampler_IrisPlaneDstTexture);

TEXTURE2D(_EyeNormalTex);    
float4 _EyeNormalTex_ST;
SAMPLER(sampler_EyeNormalTex);

TEXTURE2D(_NormalMap);    
float4 _NormalMap_ST;
SAMPLER(sampler_NormalMap);

float _IrisBrightness;
float _IrisUVRadius;

float _PupilScale;
float _ScleraBrightness;
float _ScaleByCenter;

float _IoR;
float _DepthScale;
float _FlattenNormal;
float _NormalUVScale;

float4 _CloudyIris;
float _MaskRadius;
float _Hardness;

float _LimbusWidth;
float _LimbusDarkIntensity;
float _LimbusDarkWidth;

float4 _ShadowColor;
float _ShadowRadius;
float _ShadowIntensity;

float _IrisDisplayRadius;
float _IrisDisplayStrength;

float _IrisRoughness;
float _ScleraRoughness;

float _lerp;
float _test;

float NoH;
float NoV;
float NoL;
float VoH;

float _Fresnel;

#pragma shader_feature _EyeRefraction
#pragma shader_feature _EnableShadow
#pragma shader_feature _AdditionalLights

float2 ScaleByCenter(float2 uv, float scale)
{
    return ((uv - 0.5) * (1 / scale) + 0.5);
}

VertexOutput Vertex(VertexInput v)
{
    VertexOutput o;

    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    o.pos = TransformObjectToHClip(v.vertex);
    
    o.uv = v.texcoord.xy * _IrisTexture_ST.xy + _IrisTexture_ST.zw;

    float3 worldPos = TransformObjectToWorld(v.vertex);

    VertexNormalInputs normalInput = GetVertexNormalInputs(v.normal, v.tangent);

    o.worldNormalDir = float4(normalInput.normalWS, worldPos.x);
    o.worldTangentDir = float4(normalInput.tangentWS, worldPos.y);
    o.worldBitangentDir = float4(normalInput.bitangentWS, worldPos.z);
    o.worldBinormal = cross(normalize(v.normal), normalize(v.tangent.xyz)) * v.tangent.w;

    o.TtoW1 = float3(o.worldTangentDir.x,o.worldBitangentDir.x,o.worldNormalDir.x);
    o.TtoW2 = float3(o.worldTangentDir.y,o.worldBitangentDir.y,o.worldNormalDir.y);
    o.TtoW3 = float3(o.worldTangentDir.z,o.worldBitangentDir.z,o.worldNormalDir.z);

    float3x3 rotation = transpose(float3x3(o.TtoW1, o.TtoW2, o.TtoW3));

    o.tangentViewDir = mul(rotation, normalize(_WorldSpaceCameraPos.xyz - worldPos));
    o.tangentLightDir = mul(rotation, normalize(_MainLightPosition.xyz));

    o.worldPos = worldPos;

    return o;
}

float CalculateIrisMask(float limbusWidth, float irisUVRadius, float2 uv)
{
    uv = uv - float2(0.5f, 0.5f);
    float dst = (length(uv) - irisUVRadius + limbusWidth) / limbusWidth;
    dst = saturate(1 - dst);
    return smoothstep(0,1, dst);
}

float2 ScaleIrisUV(float2 scaledUV, float pupilScale, float irisUVRadius)
{
    float2 uv = (1 / (irisUVRadius * 2.0)) * (scaledUV - 0.5) + 0.5; 

    float2 UVcentered = uv - float2(0.5f, 0.5f);
    float UVlength = length(UVcentered);

    float2 UVmax = normalize(UVcentered) * 0.5f;

    float2 UVscaled = lerp(UVmax, float2(0.f, 0.f), saturate((1.f - UVlength*2.f)*pupilScale));
    float2 t = UVscaled + float2(0.5f, 0.5f);

    return t;
}

float2 CalculateRefractedUVPhysically(float3 worldNormal ,float IoR, float3 eyeWorldNormal, float3 viewDir, float3 worldTangent, float3 irisDepthPlane,  float2 scaledUV, float irisDepthOffset, float depthScale, float mask)
{
    float2 refractedUV;

    float airIoR = 1.00029;
	float n = airIoR / IoR;

    float facing = dot(worldNormal, viewDir);

    float w = n * facing;

    float k = sqrt(1+(w-n)*(w+n));

    float3 t = (w - k)*worldNormal - n*viewDir;
    t = normalize(t);
    t = -t;

    float3 refractedViewDir = t;

    float3 irisDepth = depthScale * max(0, irisDepthPlane - float3(irisDepthOffset, irisDepthOffset, irisDepthOffset));
    float cosAlpha = dot(eyeWorldNormal, viewDir);
    float heightW = irisDepth /  lerp(0.325, 1, cosAlpha * cosAlpha);

    float3 scaledFefractedViewDir = refractedViewDir * heightW;

    float3 eyeTangent = normalize(worldTangent - dot(worldTangent, eyeWorldNormal) * eyeWorldNormal);
    float tangentOffset = dot(eyeTangent, scaledFefractedViewDir);
    float3 biNormal = cross(eyeTangent, eyeWorldNormal);
    float biNormalOffset = dot(biNormal, scaledFefractedViewDir);

    float2 RefractedUVOffset = float2(tangentOffset, biNormalOffset);
    
	refractedUV = float2(-1, -1) * _IrisUVRadius * RefractedUVOffset;

    return lerp(scaledUV, scaledUV + refractedUV, mask);
}

float3 FlipNormal(float3 normal)
{
    return float3(normal.x, -normal.y, normal.z);
}

float3 FlipViewDir(float3 viewDir)
{
    return float3(-viewDir.x, -viewDir.y, viewDir.z);
}

float3 CalculateShadow(float2 scaledUV)
{
    float3 center = float3(0.5, 0.5, 0.5);
    float3 mask = 1 - saturate((distance(float3(scaledUV, 1.0), center) - (1 - _ShadowRadius)) /  (1 - _ShadowIntensity));
    return lerp(_ShadowColor, float3(1,1,1), mask);
}

float CalculateLimbusDarkness(float2 scaledIrisUV)
{
    float darkness = length((scaledIrisUV - float2(0.5, 0.5)) * _LimbusDarkIntensity);
    return (1 - pow(darkness, 1 / _LimbusDarkWidth));
}

float3 CalculateCloudyIris(float4 _CloudyIris, float2 scaledIrisUV, float maskRadius, float _Hardness)
{
    float3 center = float3(0.5, 0.5, 0.5);
    float3 mask = 1 - saturate((distance(center, float3(scaledIrisUV, 0.0)) - maskRadius) / _Hardness);
    return _CloudyIris.rgb * mask;
}

float DiffuseTerm(VertexOutput vertexOutput, LightingData lightingData)
{
    float diffuse = 0.5 * saturate(dot(vertexOutput.worldNormalDir, lightingData.worldLightDir)) + 0.5;
    return diffuse;
}

float4 CalculateSpecular(VertexOutput vertexOutput, float3 normalToCalculate, float roughness, float3 tangentLightDir, float3 lightColor)
{
    NoH = max(saturate(dot(normalToCalculate, normalize(vertexOutput.tangentViewDir + tangentLightDir))), 0.0001);
    NoV = max(saturate(dot(normalToCalculate, vertexOutput.tangentViewDir)), 0.0001);
    NoL = max(saturate(dot(tangentLightDir, normalToCalculate)), 0.0001);
    VoH = max(saturate(dot(vertexOutput.tangentViewDir, normalize(vertexOutput.tangentViewDir + tangentLightDir))), 0.0001);

    // float D = GGXNormalDistributionFunction(roughness, NoH);
    // float G = BeckmanGeometricShadowingFunction(NoV, NoL, roughness);
    // float F = fresnelReflectance(normalize(vertexOutput.tangentViewDir + tangentLightDir), vertexOutput.tangentViewDir, 0.028);

    // float3 SpecularColor = (D * F * G) / (NoV * NoL * 4) * NoL * UNITY_PI * lightColor;
    // return float4(SpecularColor, 1.0);

    float alpha = roughness;
	float G_L = NoL + sqrt((NoL - NoL * alpha) * NoL + alpha);
	float G_V = NoV + sqrt((NoV - NoV * alpha) * NoV + alpha);
	float G = G_L * G_V;
    float3 F0 = 0.028;
	float F = fresnelReflectance(normalize(vertexOutput.tangentViewDir + tangentLightDir), vertexOutput.tangentViewDir, 0.028);
	float alpha2 = alpha * alpha;
    float denominator = (NoH * NoH) * (alpha2 - 1) + 1;
	float D = alpha2 / (3.1415926 * denominator * denominator);
	float3 specularColor = D * G * NoL * F;

    return float4(specularColor, 1.0);
}

float4 CalculateAdditionalLight(float4 FinalColor, VertexOutput vertexOutput, float roughness, float3 normalToCalculate)
{
    int lightCount = GetAdditionalLightsCount();

    float3x3 rotation = transpose(float3x3(vertexOutput.TtoW1, vertexOutput.TtoW2, vertexOutput.TtoW3));

    [unroll]
    for(int lightIndex = 0; lightIndex < lightCount; lightIndex++)
    {
        Light light = GetAdditionalLight(lightIndex, vertexOutput.worldPos);
        float3 tangentLightDir = mul(rotation, light.direction.xyz);

        float4 SpecularColor = CalculateSpecular(vertexOutput, normalToCalculate, roughness, tangentLightDir, light.color);

        FinalColor += SpecularColor;
    }

    return FinalColor;
}

float4 Frag(VertexOutput vertexOutput) : SV_Target
{
    Light light = GetMainLight();
    float2 scaledUV = ScaleByCenter(vertexOutput.uv, _ScaleByCenter);
    float2 scaledScleraNormalMapUV = ScaleByCenter(vertexOutput.uv, _NormalUVScale);
    
    float mask = CalculateIrisMask(_LimbusWidth, _IrisUVRadius, scaledUV);

    float3 irisDepth = SAMPLE_TEXTURE2D(_IrisPlaneDstTexture, sampler_IrisPlaneDstTexture, vertexOutput.uv);
    float3 irisNormal = UnpackNormal(SAMPLE_TEXTURE2D(_IrisNormalTex, sampler_IrisNormalTex, vertexOutput.uv));
    float irisDepthOffset = SAMPLE_TEXTURE2D(_IrisPlaneDstTexture, sampler_IrisPlaneDstTexture, float2(_IrisUVRadius * _ScaleByCenter + 0.5, 0.5)).r;

    float3 basicNormal = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, scaledScleraNormalMapUV));

    float3 eyeWorldNormal = UnpackNormal(SAMPLE_TEXTURE2D(_EyeNormalTex, sampler_EyeNormalTex, vertexOutput.uv));

    eyeWorldNormal = FlipNormal(eyeWorldNormal);
    LightingData lightingData = CalculateLightingData(vertexOutput, eyeWorldNormal);

    //lightingData.worldViewDir = FlipViewDir(lightingData.worldViewDir);

    float2 refractedUV = CalculateRefractedUVPhysically(vertexOutput.worldNormalDir, _IoR, lightingData.worldNormal, lightingData.worldViewDir, vertexOutput.worldTangentDir.xyz, irisDepth, scaledUV, irisDepthOffset, _DepthScale, mask);
    
    #ifdef _EyeRefraction
        float2 scaledIrisUV = ScaleIrisUV(refractedUV, _PupilScale, _IrisUVRadius);
    #else
        float2 scaledIrisUV = ScaleIrisUV(scaledUV, _PupilScale, _IrisUVRadius);
    #endif

    float4 CloudyIrisColor = float4(CalculateCloudyIris(_CloudyIris, scaledIrisUV, _MaskRadius, _Hardness), 1.0);

    float LimbusDarkness = CalculateLimbusDarkness(scaledIrisUV);
    float4 irisColor = SAMPLE_TEXTURE2D(_IrisTexture, sampler_IrisTexture, scaledIrisUV) * LimbusDarkness * _IrisBrightness;
    float4 scleraColor = SAMPLE_TEXTURE2D(_ScleraTexture, sampler_ScleraTexture, scaledUV) * _ScleraBrightness;
    float4 BasicColor = lerp(scleraColor, irisColor, mask);

    //float4 SpecularColor = float4(CalculateSpecular(vertexOutput, basicNormal, mask), 1.0);

    // #ifdef _EnableShadow
    //     float4 ShadowColor = float4(CalculateShadow(scaledUV), 1.0);
    //     FinalColor = (BasicColor + CloudyIrisColor) * ShadowColor * diffuse + SpecularColor;
    // #else
    //     FinalColor = (BasicColor + CloudyIrisColor) * diffuse + SpecularColor;
    // #endif

    // #ifdef _AdditionalLights

    //     FinalColor = CalculateAdditionalSpecular(vertexOutput, basicNormal, mask, FinalColor);

    // #endif

    //PBR Calculation

    float4 FinalColor = float4(1,1,1,1);

    float flatNess = lerp(_FlattenNormal, 1.0, mask);
    float3 scleraNormal = lerp(float4(irisNormal, 1.0), float4(0,0,1,1), flatNess).xyz;

    //Direct Specular
    // float3 normalToCalculate = lerp(float3(0,0,0), scleraNormal, mask);
    // float4 IrisSpecularColor = CalculateSpecular(vertexOutput, normalToCalculate, _IrisRoughness, vertexOutput.tangentLightDir);
    // normalToCalculate = lerp(irisNormal, float3(0,0,0), mask);
    // float4 ScleraSpecularColor = CalculateSpecular(vertexOutput, normalToCalculate, _ScleraRoughness, vertexOutput.tangentLightDir);

    //ReCalculateSpecular
    float3 normalToCalculate = scleraNormal;
    float4 IrisSpecularColor = CalculateSpecular(vertexOutput, normalToCalculate, _IrisRoughness, vertexOutput.tangentLightDir, light.color);

    //Direct Diffuse
    normalToCalculate = scleraNormal;
    float3 kd = (1 - FresnelEquation(float3(0.04, 0.04, 0.04), VoH));
    float NoL = saturate(dot(vertexOutput.tangentLightDir, scleraNormal)) * 0.8 + 0.2;
    float4 DiffuseColor = float4(BasicColor.rgb * light.color * NoL, 1.0);

    #ifdef _AdditionalLights
        
        int lightCount = GetAdditionalLightsCount();
        float3x3 rotation = transpose(float3x3(vertexOutput.TtoW1, vertexOutput.TtoW2, vertexOutput.TtoW3));

        [unroll]
        for(int lightIndex = 0; lightIndex < lightCount; lightIndex++)
        {
            Light lightAdditional = GetAdditionalLight(lightIndex, vertexOutput.worldPos);
            float3 tangentLightDir = mul(rotation, lightAdditional.direction.xyz);

            NoL = saturate(dot(tangentLightDir, scleraNormal)) * 0.5 + 0.5;

            DiffuseColor += float4(kd * BasicColor.rgb * lightAdditional.color * NoL, 1.0) * lightAdditional.distanceAttenuation * 0.1;
        }
    
    #endif

    //Indirect Specular
    // float mipLevel = _IrisRoughness * (1.7 - 0.7 * _IrisRoughness) * UNITY_SPECCUBE_LOD_STEPS;
    // float3 reflectVec = normalize(reflect(-lightingData.worldViewDir, scleraNormal));
    // float4 rgbm = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectVec, mipLevel);
    // float3 envColor = DecodeHDREnvironment(rgbm, unity_SpecCube0_HDR);
    // envColor = Luminance(envColor) * 0.2;

    // if(mask < 0.9) return DiffuseColor;
    // else return float4(envColor, 1.0) * DiffuseColor;

    //DecodeHDREnviroment(rgbm, unity_SpecCube0);
    //float3 iblSpecular = DecodeHDR(rgbm, unity_SpecCube0_HDR);  
    
	//return FinalColor;
    //return BasicColor + CloudyIrisColor + SpecularColor;
    //return DiffuseColor + CloudyIrisColor + ScleraSpecularColor + IrisSpecularColor;

    // if(mask > 0.6) return float4(envColor, 1.0) + DiffuseColor + CloudyIrisColor + ScleraSpecularColor + IrisSpecularColor;
    // else return DiffuseColor + CloudyIrisColor + ScleraSpecularColor + IrisSpecularColor;

    //return DiffuseColor + CloudyIrisColor + ScleraSpecularColor + IrisSpecularColor;

    #ifdef _EnableShadow
        float4 ShadowColor = float4(CalculateShadow(scaledUV), 1.0);
        FinalColor = (CloudyIrisColor) * ShadowColor + IrisSpecularColor;
    #else
        FinalColor = (DiffuseColor + CloudyIrisColor) + IrisSpecularColor;
    #endif

    // #ifdef _EnviromentReflection
    //     FinalColor = lerp(FinalColor, float4(envColor, 1.0) + DiffuseColor + IrisSpecularColor, mask);
    // #else
    //     FinalColor = FinalColor;
    // #endif

    #ifdef _AdditionalLights
        FinalColor = CalculateAdditionalLight(FinalColor, vertexOutput, _IrisRoughness, scleraNormal);
    #endif

    //return DiffuseColor;
    return FinalColor;
}