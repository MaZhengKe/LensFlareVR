Shader "Unlit/Billboard2"
{
    // The _BaseMap variable is visible in the Material's Inspector, as a field
    // called Base Map.
    Properties
    {
        [MainTexture] _BaseMap("Base Map", 2D) = "white"
        _FlareFalloff("_FlareFalloff", float) = 1
        _FlareEdgeOffset("_FlareEdgeOffset", float) = 1
        _size("_FlareEdgeOffset", Vector) = (1,1,1,1)
        _ScreenPos2("_ScreenPos2", Vector) = (1,1,1,1)
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
                uint vertexID : SV_VertexID;
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 color : TEXCOORD1;
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

            float4 _size;
            float4 _ScreenPos2;
            float _FlareFalloff;
            float _FlareEdgeOffset;

            CBUFFER_END

            #define _FlareSize              _size.xy
            #define _LocalCos0              _size.z
            #define _LocalSin0              _size.w

            float2 Rotate(float2 v, float cos0, float sin0)
            {
                return float2(v.x * cos0 - v.y * sin0,
                              v.x * sin0 + v.y * cos0);
            }


            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);

                float2 screenParam = GetScaledScreenParams().xy;
                float screenRatio = screenParam.y / screenParam.x;
                
                float4 positionNDC = GetVertexPositionInputs(float3(0, 0, 0)).positionNDC;

                float2 _ScreenPos = positionNDC / positionNDC.w;
                _ScreenPos = (_ScreenPos -0.5)*2;
                _ScreenPos.y = -_ScreenPos.y;

                // OUT.uv = GetQuadTexCoord(IN.vertexID);
                // float4 posPreScale = float4(2.0f, 2.0f, 1.0f, 1.0f) * GetQuadVertexPosition(IN.vertexID) - float4(1.0f, 1.0f, 0.0f, 0.0);

                float2 uv = IN.uv;
                float2 posPreScale = float4(IN.positionOS.xy, 0, 1);

                OUT.uv = uv;

                posPreScale.xy *= _FlareSize;
                float2 local = Rotate(posPreScale.xy, _LocalCos0, _LocalSin0);
                //local = posPreScale.xy;

                local.x *= screenRatio;


                OUT.positionHCS.xy = _ScreenPos.xy + local;
                OUT.positionHCS.z = 1.0f;
                OUT.positionHCS.w = 1.0f;
                

                OUT.color = ComputeScreenPos(OUT.positionHCS);
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
                //return half4(IN.color.xy, 0, 1);
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