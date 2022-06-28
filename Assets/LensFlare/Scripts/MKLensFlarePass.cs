using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class MKLensFlarePass : ScriptableRenderPass
{
    // This method is called before executing the render pass.
    // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
    // When empty this render pass will render to the active camera render target.
    // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
    // The render pipeline will ensure target setup and clearing happens in a performant manner.
    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
    }

    internal enum MKProfileId
    {
        LensFlareDataDriven
    }

    const string k_RenderPostProcessingTag = "MK Render PostProcessing Effects";
    const string k_RenderFinalPostProcessingTag = "Render Final PostProcessing Pass";

    private static readonly ProfilingSampler m_ProfilingRenderPostProcessing =
        new ProfilingSampler(k_RenderPostProcessingTag);


    public Material m_Material;
    public ScriptableRenderer m_Renderer;

    RenderTextureDescriptor m_Descriptor;

    void Render(CommandBuffer cmd, ref RenderingData renderingData)
    {
        ref CameraData cameraData = ref renderingData.cameraData;

        bool useLensFlare = !LensFlareCommonMK.Instance.IsEmpty();
        //Debug.Log($"useLensFlare:{useLensFlare}");

        // Lens Flare
        if (useLensFlare)
        {
            bool usePanini;
            float paniniDistance;
            float paniniCropToFit;
            // if (m_PaniniProjection.IsActive())
            // {
            //     usePanini = true;
            //     paniniDistance = m_PaniniProjection.distance.value;
            //     paniniCropToFit = m_PaniniProjection.cropToFit.value;
            // }
            // else
            {
                usePanini = false;
                paniniDistance = 1.0f;
                paniniCropToFit = 1.0f;
            }

            using (new ProfilingScope(cmd, ProfilingSampler.Get(MKProfileId.LensFlareDataDriven)))
            {
                DoLensFlareDatadriven(cameraData.camera, cmd, m_Renderer.cameraColorTarget, usePanini, paniniDistance,
                    paniniCropToFit);
            }
        }
    }

    Matrix4x4 getMatrixFromEye(Camera camera, Camera.StereoscopicEye eye)
    {
        var gpuView = camera.GetStereoViewMatrix(eye);
        var gpuNonJitteredProj = GL.GetGPUProjectionMatrix(camera.GetStereoNonJitteredProjectionMatrix(eye), true);
        // Zero out the translation component.
        gpuView.SetColumn(3, new Vector4(0, 0, 0, 1));
        var gpuVP = gpuNonJitteredProj * gpuView;

        return gpuVP;
    }

    void DoLensFlareDatadriven(Camera camera, CommandBuffer cmd, RenderTargetIdentifier source, bool usePanini,
        float paniniDistance, float paniniCropToFit)
    {
        var leftGpuVP = getMatrixFromEye(camera, Camera.StereoscopicEye.Left);
        var rightGpuVP = getMatrixFromEye(camera, Camera.StereoscopicEye.Right);

        var gpuView = camera.worldToCameraMatrix;
        var gpuNonJitteredProj = GL.GetGPUProjectionMatrix(camera.projectionMatrix, true);
        // Zero out the translation component.
        gpuView.SetColumn(3, new Vector4(0, 0, 0, 1));
        var gpuVP = gpuNonJitteredProj * camera.worldToCameraMatrix;

        //gpuVP = camera.GetStereoNonJitteredProjectionMatrix()
//        Debug.Log(eye);
//        Debug.Log(m_Descriptor.width);

        LensFlareCommonMK.DoLensFlareDataDrivenCommon(m_Material, LensFlareCommonMK.Instance, camera,
            (float)m_Descriptor.width, (float)m_Descriptor.height,
            usePanini, paniniDistance, paniniCropToFit,
            true,
            camera.transform.position,
            gpuVP,
            leftGpuVP,
            rightGpuVP,
            cmd, source,
            (light, cam, wo) => { return GetLensFlareLightAttenuation(light, cam, wo); },
            ShaderConstants._FlareOcclusionTex, ShaderConstants._FlareOcclusionIndex,
            ShaderConstants._FlareTex, ShaderConstants._FlareColorValue,
            ShaderConstants._FlareData0, ShaderConstants._FlareData1, ShaderConstants._FlareData2,
            ShaderConstants._FlareData3, ShaderConstants._FlareData4,
            false);
    }

    static float GetLensFlareLightAttenuation(Light light, Camera cam, Vector3 wo)
    {
        // Must always be true
        if (light != null)
        {
            switch (light.type)
            {
                case LightType.Directional:
                    return LensFlareCommonSRP.ShapeAttenuationDirLight(light.transform.forward, wo);
                case LightType.Point:
                    return LensFlareCommonSRP.ShapeAttenuationPointLight();
                case LightType.Spot:
                    return LensFlareCommonSRP.ShapeAttenuationSpotConeLight(light.transform.forward, wo,
                        light.spotAngle, light.innerSpotAngle / 180.0f);
                default:
                    return 1.0f;
            }
        }
        return 1.0f;
    }


    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        var cmd = CommandBufferPool.Get();
        using (new ProfilingScope(cmd, m_ProfilingRenderPostProcessing))
        {
            Render(cmd, ref renderingData);
        }

        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }

    // Cleanup any allocated resources that were created during the execution of this render pass.
    public override void OnCameraCleanup(CommandBuffer cmd)
    {
    }

    public void Setup(RenderTextureDescriptor baseDescriptor, ScriptableRenderer renderer, Material material)
    {
        m_Descriptor = baseDescriptor;
        m_Material = material;
        m_Renderer = renderer;
    }
}