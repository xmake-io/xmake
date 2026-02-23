using LibAlpha;

namespace LibBeta;

public static class Beta
{
    public static string Message()
    {
        return Alpha.Message() + "+beta";
    }
}

