Shader "URP/EyeWater"
{
    Properties
    {
        _Fade("Fade", Range(1, 10)) = 5
        _Smoothness("Smoothness", Range(0, 1)) = 0.5
        _SpecularColor("Specular Color", Color) = (1,1,1,1)
        _EnvCube("Enviroment Cube", 3D) = "" {}
    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent"}
        Blend SrcAlpha OneMinusSrcAlpha
        //Blend OneMinusDstAlpha One
        ZWrite Off
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "PBRFunction.hlsl"

            #define UNITY_PI 3.14159265359f
 
            struct Attributes
            {
                float4 vertexOS : POSITION;  
                half3 normalOS:NORMAL;
                float2 texcoord : TEXCOORD0;
            };
 
            struct Varyings
            {  
                float4 vertexCS : SV_POSITION;
                half3 normalWS:TEXCOORD;
                float3 vertexWS:TEXCOORD1;
                float2 uv : TEXCOORD2;
                float4 screenPos: TEXCOORD3;
            };

            TEXTURECUBE(_EnvCube);
            SAMPLER(sampler_EnvCube); 
 
            float _Fade;
            float _Smoothness;
            float4 _SpecularColor;

            TEXTURE2D(_CameraOpaqueTexture); 
            float4 _CameraOpaqueTexture_ST;
            SAMPLER(sampler_CameraOpaqueTexture);

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.vertexCS = TransformObjectToHClip(v.vertexOS);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.vertexWS=TransformObjectToWorld(v.vertexOS);
                o.uv = v.texcoord.xy * _CameraOpaqueTexture_ST.xy + _CameraOpaqueTexture_ST.zw;
                o.screenPos = ComputeScreenPos(o.vertexCS);
                return o;
            }

            float Fresnel(float3 normal, float3 viewDir, float power)
            {
                return pow((1.0 - saturate(dot(normal, viewDir))), power);
            }
 
            float4 frag (Varyings i) : SV_Target
            {
                float3 N = normalize(i.normalWS);
                float3 V = normalize(_WorldSpaceCameraPos - i.vertexWS);
                float3 L = normalize(_MainLightPosition.xyz);

                float fresnel = Fresnel(N, V, _Fade);
                
                float NoH = max(saturate(dot(N, normalize(V + L))), 0.0001);
                float NoV = max(saturate(dot(N, V)), 0.0001);
                float NoL = max(saturate(dot(L, N)), 0.0001);
                float VoH = max(saturate(dot(V, normalize(V + L))), 0.0001);

                float D = GGXNormalDistributionFunction(_Smoothness, NoH);
                float G = BeckmanGeometricShadowingFunction(NoV, NoL, _Smoothness);

                float4 SpecularColor = float4(((D * G) / (NoV * NoL * 4)) * NoL * UNITY_PI * _SpecularColor.rgb, 1.0);

                float mipLevel = _Smoothness * (1.7 - 0.7 * _Smoothness) * UNITY_SPECCUBE_LOD_STEPS;
                float3 reflectVec = normalize(reflect(-V, N));
                float4 rgbm = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectVec, mipLevel);
                float3 envColor = DecodeHDREnvironment(rgbm, unity_SpecCube0_HDR);

                float2 screenUV = i.screenPos.xy / i.screenPos.w;

                float3 basicColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, screenUV);

                return float4(envColor * 3.0, 0.05);
                //return float4(basicColor, 1.0) * float4(1,1,1,1);
            }
            ENDHLSL
        }
    }
}