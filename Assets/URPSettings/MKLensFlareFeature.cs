using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class MKLensFlareFeature : ScriptableRendererFeature
{
    MKLensFlarePass m_ScriptablePass;
    
    private const string k_ShaderName = "Hidden/Universal Render Pipeline/MKLensFlareDataDriven";
    private Material m_Material;
    
    [SerializeField, HideInInspector] private Shader m_Shader;
    

    /// <inheritdoc/>
    public override void Create()
    {
        m_ScriptablePass = new MKLensFlarePass();

        // Configures where the render pass should be injected.
        m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        m_Shader = Shader.Find(k_ShaderName);
        m_Material = CoreUtils.CreateEngineMaterial(m_Shader);
        
        m_ScriptablePass.Setup(renderingData.cameraData.cameraTargetDescriptor,renderer, m_Material);
        renderer.EnqueuePass(m_ScriptablePass);
    }
}


