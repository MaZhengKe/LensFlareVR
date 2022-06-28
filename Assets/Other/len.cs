using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.XR;

public class len : MonoBehaviour
{
    public Camera cam;

    public Matrix4x4 worldToCameraMatrix;
    public Matrix4x4 Matrix;
    // Start is called before the first frame update
    void Start()
    {
        cam.GetStereoProjectionMatrix(Camera.StereoscopicEye.Left);
        
        worldToCameraMatrix = cam.worldToCameraMatrix;
        var gpuNonJitteredProj = GL.GetGPUProjectionMatrix(cam.projectionMatrix, true);
        Matrix = gpuNonJitteredProj * cam.worldToCameraMatrix;
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
