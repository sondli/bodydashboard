defmodule BodydashboardWeb.Icons do
  use Phoenix.Component

  def drop_icon(assigns) do
    ~H"""
    <svg
      class="w-6 h-6 fill-white stroke-white stroke-1 hover:scale-110 active:scale-90 transform origin-center transition-all duration-300"
      viewBox="0 0 32 32"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path d="M15.95 31.959c-6.041 0-10.956-4.848-10.956-10.806 0-6.959 9.739-20.151 10.153-20.71 0.188-0.252 0.482-0.402 0.796-0.404 0.349-0.003 0.611 0.144 0.802 0.393 0.419 0.548 10.261 13.507 10.261 20.721 0 5.959-4.96 10.806-11.056 10.806zM15.961 2.74c-2.325 3.302-8.967 13.189-8.967 18.413 0 4.855 4.018 8.806 8.956 8.806 4.993 0 9.056-3.95 9.056-8.806 0-5.418-6.692-15.157-9.045-18.413z">
      </path>
    </svg>
    """
  end

  def body_icon(assigns) do
    ~H"""
    <svg
      class="w-6 h-6 fill-white hover:scale-110 active:scale-90 transform origin-center transition-all duration-300"
      viewBox="0 0 512 512"
      xmlns="http://www.w3.org/2000/svg"
    >
      <circle cx="256" cy="56" r="56" />
      <path d="M437,128H75a27,27,0,0,0,0,54H176.88c6.91,0,15,3.09,19.58,15,5.35,13.83,2.73,40.54-.57,61.23l-4.32,24.45a.42.42,0,0,1-.12.35l-34.6,196.81A27.43,27.43,0,0,0,179,511.58a27.06,27.06,0,0,0,31.42-22.29l23.91-136.8S242,320,256,320c14.23,0,21.74,32.49,21.74,32.49l23.91,136.92a27.24,27.24,0,1,0,53.62-9.6L320.66,283a.45.45,0,0,0-.11-.35l-4.33-24.45c-3.3-20.69-5.92-47.4-.57-61.23,4.56-11.88,12.91-15,19.28-15H437a27,27,0,0,0,0-54Z" />
    </svg>
    """
  end

  def profile_icon(assigns) do
    ~H"""
    <svg
      class="w-6 h-6 fill-white hover:scale-110 active:scale-90 transform origin-center transition-all duration-300"
      viewBox="0 0 20 20"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path d="M10,10 C7.794,10 6,8.206 6,6 C6,3.794 7.794,2 10,2 C12.206,2 14,3.794 14,6 C14,8.206 12.206,10 10,10 M13.758,10.673 C15.124,9.574 16,7.89 16,6 C16,2.686 13.314,0 10,0 C6.686,0 4,2.686 4,6 C4,7.89 4.876,9.574 6.242,10.673 C2.583,12.048 0,15.445 0,20 L2,20 C2,15 5.589,12 10,12 C14.411,12 18,15 18,20 L20,20 C20,15.445 17.417,12.048 13.758,10.673" />
    </svg>
    """
  end
end
