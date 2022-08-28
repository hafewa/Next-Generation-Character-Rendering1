Shader "URP/EyeAround"
{
    Properties
    {
        _Fade("Fade", Range(0, 10)) = 5
        _Smoothness("Smoothness", Range(0, 1)) = 0.5
        _SpecularColor("Specular Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent"
         }
        Blend One One
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
            };
 
            struct Varyings
            {  
                float4 vertexCS : SV_POSITION;
                half3 normalWS:TEXCOORD;
                float3 vertexWS:TEXCOORD1;
            };
 
            float _Fade;
            float _Smoothness;
            float4 _SpecularColor;

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.vertexCS = TransformObjectToHClip(v.vertexOS);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.vertexWS=TransformObjectToWorld(v.vertexOS);
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

                //float specular = saturate(dot(N, normalize(V + L)));

                return SpecularColor * fresnel;
            }
            ENDHLSL
        }
    }
}