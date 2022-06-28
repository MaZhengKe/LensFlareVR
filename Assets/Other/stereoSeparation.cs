using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class stereoSeparation : MonoBehaviour
{
    public Camera cam;

    public float dis;
    public float dis2;
    // Start is called before the first frame update
    void Start()
    {
    }

    // Update is called once per frame
    void Update()
    {
        dis2 = cam.stereoSeparation;
        //cam.stereoSeparation = dis;
    }
}
