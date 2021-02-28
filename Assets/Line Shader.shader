  Shader "Line Shader"
{
    Properties
    {
		_LineWidth("Line Width", range(0,.1)) = .02
		_MainCol("Main Color", Color) = (1,0,0,0)
		_BlingCol("Bling Color", Color) = (1,0,0,0)
		_SheenCol("Sheen Color", Color) = (1,0,0,0)
		_Timer("Time", float) = 0
    }
    SubShader
    {
        Cull Off ZWrite Off ZTest Always

		Tags { "Queue" = "Overlay"}
        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata
            {
                float4 pos : POSITION;
				float2 uv : TEXCOORD0;
				float4 ray : TEXCOORD1;
            };

			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float2 uv_depth : TEXCOORD1;
				float4 interpolatedRay : TEXCOORD2;
			};

			sampler2D _MainTex;
			sampler2D _MetalLineTexture;
			sampler2D_float _CameraDepthTexture;
			float4 _WorldSpaceScannerPos;
			float3 _Metal1Pos;
			float _LineWidth;
			float _Timer;
			float4 _MainCol;
			float4 _BlingCol;
			float4 _SheenCol;
			sampler2D _Metals;
			
			v2f vert(appdata i)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(i.pos);
				o.uv = i.uv;
				o.uv_depth = i.uv.xy;
				o.interpolatedRay = i.ray;
				return o;
			}
			
			// float isOnLineToPoint(float2 uv, float2 p)
			// {
			// 	p.x -= 0.5;
			// 	uv.x -= 0.5;
			// 	float l = length(p);
			// 	p = p / l * length(uv);
			// 	float deltaX = p.x - uv.x;
			// 	float deltaY = p.y - uv.y;

			// 	return
			// 		deltaX > -_LineWidth  &&
			// 		deltaX < _LineWidth &&
			// 		deltaY > -_LineWidth * 1.6 &&
			// 		deltaY < _LineWidth * 1.6 &&
			// 		length(uv) < l;
			// }

			float intersect(float3 p1, float3 p2, float3 q1, float3 q2, float w, out float d, out float e)
			{
				float3 p = p1;
				float3 q = q1;
				float3 r = p2 - p1;
				float3 s = q2 - q1;

				float x1 = p1.x;
				float x2 = p2.x;
				float x3 = q1.x;
				float x4 = q2.x;
				float y1 = p1.y;
				float y2 = p2.y;
				float y3 = q1.y;
				float y4 = q2.y;
				float z1 = p1.z;
				float z2 = p2.z;
				float z3 = q1.z;
				float z4 = q2.z;

				// d(mnop) = (xm - xn)(xo - xp) + (ym - yn)(yo - yp) + (zm - zn)(zo - zp)

				float d1343 = (x1-x3) * (x4-x3) + (y1-y3) * (y4-y3) + (z1-z3) * (z4-z3);
				float d4321 = (x4-x3) * (x2-x1) + (y4-y3) * (y2-y1) + (z4-z3) * (z2-z1);
				float d1321 = (x1-x3) * (x2-x1) + (y1-y3) * (y2-y1) + (z1-z3) * (z2-z1);
				float d4343 = (x4-x3) * (x4-x3) + (y4-y3) * (y4-y3) + (z4-z3) * (z4-z3);
				float d2121 = (x2-x1) * (x2-x1) + (y2-y1) * (y2-y1) + (z2-z1) * (z2-z1);

				float mua = ( d1343 * d4321 - d1321 * d4343 ) / ( d2121 * d4343 - d4321 * d4321 );
				float mub = ( d1343 + mua * d4321 ) / d4343;

				float3 pi = p + mua * r;
				float3 qi = q + mub * s;

				float3 pqi = pi - qi;

				d = length(pqi);
				e = mub;

				float3 n1 = cross(p2 - p1, q1 - p1);
				float3 n2 = cross(p2 - p1, q2 - p1);
				float3 n3 = cross(q2 - q1, p1 - q1);
				float3 n4 = cross(q2 - q1, p2 - q1);

				float c = dot(cross(r / length(r),s), p-q);
				
				return 
					dot(n1,n2) < 0 &&
					dot(n3,n4) < 0 &&
					c < w &&
					c > (0 - w);
			}

			float4 frag(v2f i) : COLOR
			{	
				fixed4 col = tex2D(_MainTex, i.uv);

				float rawDepth = DecodeFloatRG(tex2D(_CameraDepthTexture, i.uv_depth));
				float linearDepth = Linear01Depth(rawDepth);
				float4 wsDir = linearDepth * i.interpolatedRay;
				float3 wsPos = _WorldSpaceCameraPos + wsDir;

				half4 scannerCol = half4(0.5,0,0,0);

				float4 m1pos = tex2D(_Metals, float2(0,0)); // this does not work yet :(
				// float4 m1pos = float4(0,0,0,0);

				// float3 wsMetalDir = m1pos - _WorldSpaceScannerPos;

				// float a = -_CameraRotation * UNITY_PI / 180;
				// float3x3 rotationMatrix = float3x3(cos(a), 0, sin(a), 0, 1, 0, -sin(a), 0, cos(a));
				// float3 camMetalDir = mul(rotationMatrix, wsMetalDir.xyz);

				float3 scannerPos = _WorldSpaceScannerPos - float3(0, .5, 0);

				float d;
				float e;
				float b = intersect(_WorldSpaceScannerPos, wsPos, scannerPos, _Metal1Pos, _LineWidth, d, e);
				if (b && d < _LineWidth / 10)
				{
					float s = e - _Timer;
					float4 c = lerp(_MainCol, _BlingCol, 1 - _Timer);
					c = lerp(c, _SheenCol, s < .1 && s > 0);
					col = lerp(col, c, (1-d*100) * (1-e));
				}

				return col;
			}
			ENDCG
		}
	}
}
