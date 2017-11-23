using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class setDepthTexture : MonoBehaviour {
	void OnEnable() {
		Camera.main.depthTextureMode |= DepthTextureMode.Depth;
	}
}
