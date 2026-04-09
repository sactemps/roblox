-- Share gun properties across multiple files.

local module = {
	equipped = false;
	aiming = false;
	gun = nil;
	fpvGun = nil;
	recoilOffset = CFrame.identity;
	cameraRecoilOffset = CFrame.identity;
}

return module