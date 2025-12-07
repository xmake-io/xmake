struct PSInput {
    float4 position : SV_POSITION;
    float2 texcoord : TEXCOORD0;
};

float4 main(PSInput input) : SV_TARGET {
    return float4(input.texcoord, 0.0, 1.0);
}

