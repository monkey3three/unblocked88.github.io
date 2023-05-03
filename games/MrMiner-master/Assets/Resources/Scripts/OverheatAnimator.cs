using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class OverheatAnimator : MonoBehaviour
{
    public Animator animator;
    public SellButton sellButton;
    public void Begin()
    {
        if (!sellButton.overheated)
            animator.enabled = false;
    }

    public void End()
    {
        if (sellButton.overheated)
            animator.enabled = false;
    }
}
