using UnityEngine;

public class NewShopItemAnimation : MonoBehaviour
{
    public Animator canvasAnimator;
    private static readonly int ScrollViewShow = Animator.StringToHash("ScrollViewShow");

    public void End()
    {
        canvasAnimator.SetTrigger(ScrollViewShow);
        gameObject.SetActive(false);
    }
}