Shader "URP/EyeShader"
{
	Properties
	{
		[Header(Basic Texture)]
		_IrisTexture("Iris Texture", 2D) = "white" {}
		_IrisBrightness("IrisBrightness", float) = 0.7
		_IrisUVRadius("IrisUVRadius", Range(0.1, 0.25)) = 0.15
		_ScleraTexture("ScleraTexture", 2D) = "white" {}
		_ScleraBrightness("ScleraBrightness", float) = 0.9
		_IrisPlaneDstTexture("Iris Plane Dst Texture", 2D) = "white" {}
		_IoR("IoR", Range(1.00029, 10.0)) = 1.2
		_DepthScale("Depth Scale", Range(0,10.0)) = 1.0
		_FlattenNormal("FlattenNormal", Range(0.0, 1.0)) = 0.7
		_NormalUVScale("NormalUVScale", Range(0.0, 5.0)) = 0.9
		_Fresnel("Fresnel", Range(0, 1)) = 0.5

		[Header(Cloudy Iris)]
		_CloudyIris("Cloudy Iris", Color) = (1,1,1,1)
		_MaskRadius("Mask Radius", Range(0, 1.0)) = 0.18
		_Hardness("Hardness", Range(0, 1)) = 0.2

		[Header(Pupile Scale)]
		_PupilScale("PupilScale", float) = 0.85
		
		[Header(Normal Texture)]
		_IrisNormalTex("Irish Normal", 2D) = "white" {}
		_EyeNormalTex("Eye Normal Texture", 2D) = "white" {}
		_NormalMap("Normal map", 2D) = "white" {}

		[Header(Limbus)]
		_LimbusWidth("Limbus Range", Range(0.0, 0.2)) = 0.08
		_LimbusDarkIntensity("Limbus Dark Intensity", Range(1.0, 2.5)) = 1.5
		_LimbusDarkWidth("LimbusDarkWidth", Range(0.01, 3.0)) = 2.0

		[Header(Shadow)]
		_ShadowColor("Shadow Color", Color) = (1,1,1,1)
		_ShadowRadius("Shadow Radius", Range(0.0, 1.0)) = 0.21
		_ShadowIntensity("Shadow Intensity", Range(0.0, 1.0)) = 0.5

		_ScaleByCenter("Scale By Center", Range(0.1, 3)) = 1.0

		[Header(PBR Settings)]
		_IrisRoughness("Iris Roughness", Range(0.001, 1)) = 0.004
		_ScleraRoughness("ScleraRoughness", Range(0, 1)) = 0.5

		[Header(Test)]
		_test("test", Range(0, 1)) = 0.5

		[Header(Bool Settings)]
		[Toggle(_EyeRefraction)] _EyeRefraction("_EyeRefraction", float) = 1
		[Toggle(_EnableShadow)] _EnableShadow("_EnableShadow", float) = 1
		[Toggle(_AdditionalLights)] _AdditionalLights("_AdditionalLights", float) = 1
	}

	SubShader
	{
        Tags 
		{
            "IgnoreProjector"="True"
            "RenderPipeline" = "UniversalPipeline"
        }

		Pass
		{
			Name "ForwardLit"
			Tags { "LightMode" = "UniversalForward"}

			HLSLPROGRAM

			#pragma vertex Vertex
			#pragma fragment Frag

			#pragma target 3.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "EyeBase.hlsl"

			ENDHLSL
		}
	}

	FallBack "VertexLit"
}