using System.Net;
using System.Globalization;
using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class MetalFinder : MonoBehaviour
{
    public Material Material;
	public Transform Metal1;
	public Transform[] Metals;
    private Camera _camera;
	private float time;

    void OnEnable()
    {
        _camera = GetComponent<Camera>();
		_camera.depthTextureMode = DepthTextureMode.Depth;
		time = 0;
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
		time += Time.deltaTime;
		if (time > 1) time -= 1;
		Material.SetVector("_WorldSpaceScannerPos", _camera.transform.position);
		Material.SetVector("_Metal1Pos", Metal1.transform.position);
		Material.SetFloat("_Timer", time);

		// this does not work yet :(
		// Texture2D metalPosTex = new Texture2D(1, Metals.Length);
		// for (int i = 0; i < Metals.Length; i++) 
		// {
		// 	UnityEngine.Vector3 m = Metals[i].position;
		// 	Color c = new Color(m.x, m.y, m.z, 0);
		// 	metalPosTex.SetPixel(0,i,c);
		// }
		// metalPosTex.Apply();
		// Material.SetTexture("_Metals", metalPosTex);

        RaycastCornerBlit(source, destination);
    }

    void RaycastCornerBlit(RenderTexture source, RenderTexture destination)
    {
		float camFar = _camera.farClipPlane;
        float camFov = _camera.fieldOfView;
        float camAspect = _camera.aspect;
        float fovWHalf = camFov * 0.5f;

        Vector3 toRight = _camera.transform.right * Mathf.Tan(fovWHalf * Mathf.Deg2Rad) * camAspect;
        Vector3 toTop = _camera.transform.up * Mathf.Tan(fovWHalf * Mathf.Deg2Rad);

        Vector3 topLeft = (_camera.transform.forward - toRight + toTop);
        float camScale = topLeft.magnitude * camFar;
        topLeft.Normalize();
        topLeft *= camScale;

        Vector3 topRight = (_camera.transform.forward + toRight + toTop);
        topRight.Normalize();
        topRight *= camScale;

        Vector3 bottomRight = (_camera.transform.forward + toRight - toTop);
        bottomRight.Normalize();
        bottomRight *= camScale;

        Vector3 bottomLeft = (_camera.transform.forward - toRight - toTop);
        bottomLeft.Normalize();
        bottomLeft *= camScale;

		RenderTexture.active = destination;
        Material.SetTexture("_MainTex", source);

        GL.PushMatrix();
        GL.LoadOrtho();

        Material.SetPass(0);

        GL.Begin(GL.QUADS);

        GL.MultiTexCoord2(0, 0.0f, 0.0f);
        GL.MultiTexCoord(1, bottomLeft);
        GL.Vertex3(0.0f, 0.0f, 0.0f);

        GL.MultiTexCoord2(0, 1.0f, 0.0f);
        GL.MultiTexCoord(1, bottomRight);
        GL.Vertex3(1.0f, 0.0f, 0.0f);

		GL.MultiTexCoord2(0, 1.0f, 1.0f);
        GL.MultiTexCoord(1, topRight);
        GL.Vertex3(1.0f, 1.0f, 0.0f);

        GL.MultiTexCoord2(0, 0.0f, 1.0f);
        GL.MultiTexCoord(1, topLeft);
        GL.Vertex3(0.0f, 1.0f, 0.0f);

        GL.End();

        GL.PopMatrix();
    }

}
