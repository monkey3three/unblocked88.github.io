using UnityEngine;

public class ScaleWithScreen : MonoBehaviour
{
    public bool keepAspectRatio;
    public bool keepAspectRatioOnX;

    private void Start()
    {
        var mainCamera = GameObject.FindGameObjectWithTag("MainCamera").GetComponent<Camera>();
        var topRightCorner =
            mainCamera.ScreenToWorldPoint(new Vector3(Screen.width, Screen.height, mainCamera.transform.position.z));
        var worldSpaceWidth = topRightCorner.x * 2;
        var worldSpaceHeight = topRightCorner.y * 2;

        var spriteSize = gameObject.GetComponent<SpriteRenderer>().bounds.size;

        var scaleFactorX = worldSpaceWidth / spriteSize.x;
        var scaleFactorY = worldSpaceHeight / spriteSize.y;

        if (keepAspectRatio)
            if (keepAspectRatioOnX)
                scaleFactorY = scaleFactorX;
            else if (scaleFactorX > scaleFactorY)
                scaleFactorY = scaleFactorX;
            else
                scaleFactorX = scaleFactorY;

        gameObject.transform.localScale = new Vector3(scaleFactorX, scaleFactorY, 1);
    }
}