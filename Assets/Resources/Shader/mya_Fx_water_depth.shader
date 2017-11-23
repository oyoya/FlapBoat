// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

/*
@喵喵mya
2017-04-07 10:57:33

基于深度图以及法线贴图的海水Shader
根据深度在与其他物体的交界处逐渐透明

不能接收实时光

*/
Shader "Mya/Fx/water_depth"
{

	Properties {		
    _WaterColor("WaterColor",Color) = (0,.25,.4,1)//海水颜色
    _FarColor("FarColor",Color)=(.2,1,1,.3)//反射颜色
    _BumpMap("BumpMap", 2D) = "white" {}//法线贴图
    _BumpPower("BumpPower",Range(-1,1))=.6//法线强度
    _EdgeRange("EdgeRange",Range(0.1,10))=.4//边缘混合强度
    _WaveSize("WaveSize",Range(0.01,1))=.25//波纹大小
    _WaveOffset("WaveOffset(xy&zw)",vector)=(.1,.2,-.2,-.1)//波纹流动方向
    _LightColor("LightColor",Color)=(1,1,1,1)//光源颜色
    _LightVector("LightVector(xyz for lightDir,w for power)",vector)=(.5,.5,.5,100)//光源方向
	}
		SubShader{
				Tags{ 
                "RenderType" = "Opaque" 
                "Queue" = "Transparent"
                }
				Blend SrcAlpha OneMinusSrcAlpha
				LOD 200
		Pass{
		    CGPROGRAM
	        #pragma vertex vert
	        #pragma fragment frag
	        #pragma multi_compile_fog
            #pragma multi_compile DEPTH_ON DEPTH_OFF
            #pragma target 3.0
            #include "UnityCG.cginc"

        fixed4 _WaterColor;
        fixed4 _FarColor;

    	sampler2D _BumpMap;
    	half _BumpPower;

    	half _WaveSize;
        half4 _WaveOffset;

        #ifdef DEPTH_ON
        half _EdgeRange;
        sampler2D_float _CameraDepthTexture;
        #endif

        fixed4 _LightColor;
        half4 _LightVector;

		struct a2v {
			float4 vertex:POSITION;
			half3 normal : NORMAL;
		};
		struct v2f
		{
			half4 pos : POSITION;
			half3 normal:TEXCOORD1;
            half4 screenPos:TEXCOORD2;
            half3 viewDir:TEXCOORD3;
            half4 uv : TEXCOORD4;
             UNITY_FOG_COORDS(5)
		};

		//unity没有取余的函数，自己写一个
		half2 fract(half2 val)
		{
			return val - floor(val);
		}

		v2f vert(a2v v)
		{
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
            float4 wPos = mul(unity_ObjectToWorld,v.vertex);
            o.uv.xy = wPos.xz * _WaveSize + _WaveOffset.xy * _Time.y;
            o.uv.zw = wPos.xz * _WaveSize + _WaveOffset.zw * _Time.y;
            o.normal = UnityObjectToWorldNormal(v.normal);
            o.viewDir = WorldSpaceViewDir(v.vertex);
            o.screenPos = ComputeScreenPos(o.pos);
            COMPUTE_EYEDEPTH(o.screenPos.z);
            UNITY_TRANSFER_FOG ( o , o.pos );
			return o;
		}


		fixed4 frag(v2f i):COLOR {

			//海水颜色
            fixed4 col=_WaterColor;

            //计算法线
            half3 nor = UnpackNormal((tex2D(_BumpMap,fract(i.uv.xy)) + tex2D(_BumpMap,fract(i.uv.zw * 1.2)))*0.5);  
            nor= normalize(i.normal + nor.xyz *half3(1,1,0)* _BumpPower);  

           	//计算高光
            half spec =max(0,dot(nor,normalize(normalize(_LightVector.xyz)+normalize(i.viewDir))));  
            spec = pow(spec,_LightVector.w); 

            //计算菲涅耳反射
            half fresnel=1-saturate(dot(nor,normalize(i.viewDir))); 
            col=lerp(col,_FarColor,fresnel); 

            //计算海水边缘以及海浪
            #ifdef DEPTH_ON  
            half depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPos)));  
            depth = saturate((depth-i.screenPos.z)*_EdgeRange);  
			//depth = pow(depth,0.5); 
            col.a = lerp(0,col.a,depth);
            #endif  

            col.rgb+= _LightColor*spec;  
            UNITY_APPLY_FOG(i.fogCoord, col);
            return col;  
}
		ENDCG
	}
	}
	FallBack OFF
}