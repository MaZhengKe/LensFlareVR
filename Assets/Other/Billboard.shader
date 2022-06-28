Shader "Unlit/Billboard"
{
    // The _BaseMap variable is visible in the Material's Inspector, as a field
    // called Base Map.
    Properties
    {
        [MainTexture] _BaseMap("Base Map", 2D) = "white"
        _FlareFalloff("_FlareFalloff", float) = 1
        _FlareEdgeOffset("_FlareEdgeOffset", float) = 1
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            
            Blend One One
            ZWrite Off
            Cull Off
            ZTest Always
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            // This macro declares _BaseMap as a Texture2D object.
            TEXTURE2D(_BaseMap);
            // This macro declares the sampler for the _BaseMap texture.
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
            // The following line declares the _BaseMap_ST variable, so that you
            // can use the _BaseMap variable in the fragment shader. The _ST
            // suffix is necessary for the tiling and offset function to work.
            float4 _BaseMap_ST;
            
            float _FlareFalloff;
            float _FlareEdgeOffset;
            
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);

                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);

                #if defined(USING_STEREO_MATRICES)
                
                float3 newZ = TransformWorldToObject(GetCameraPositionWS());

                #else
                
                float3 newZ = TransformWorldToObject(GetCameraPositionWS());
                
                #endif
                
                newZ = -normalize(newZ);
                
                //判断是否开启了锁定Z轴
                #ifdef _Z_STAGE_LOCK_Z
                newZ.y=0;
                #endif
                newZ = normalize(newZ);
                //根据Z的位置去判断x的方向
                float3 newX = abs(newZ.y) < 0.99 ? cross(float3(0, 1, 0), newZ) : cross(newZ, float3(0, 0, 1));
                newX = normalize(newX);
                float3 newY = cross(newZ, newX);
                newY = normalize(newY);
                float3x3 Matrix = {newX, newY, newZ}; //这里应该取矩阵的逆 但是hlsl没有取逆矩阵的函数
                float3 newpos = mul(IN.positionOS.xyz * float3(0.5,2,1), Matrix);
                OUT.positionHCS = TransformObjectToHClip(newpos);
                return OUT;
            }

            
float4 ComputeCircle(float2 uv)
{
    float2 v = (uv - 0.5f) * 2.0f;

    const float epsilon = 1e-3f;
    const float epsCoef = pow(epsilon, 1.0f / _FlareFalloff);

    float x = length(v);

    float sdf = saturate((x - 1.0f) / ((_FlareEdgeOffset - 1.0f)));

#if defined(FLARE_INVERSE_SDF)
    sdf = saturate(sdf);
    sdf = InverseGradient(sdf);
#endif

    return pow(sdf, _FlareFalloff);
}

            

            half4 frag(Varyings IN) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);
                return ComputeCircle(IN.uv);
                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);

                //color = half4(_WorldSpaceCameraPos, 1);
                // #if defined(USING_STEREO_MATRICES)
                // color = half4(1,0,0,1);
                // #endif

                return color;
            }
            ENDHLSL
        }
    }
}