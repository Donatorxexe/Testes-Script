import React from 'react';

function App() {
  return (
    <div className="flex h-screen bg-[#080808] text-white font-sans">
      {/* Sidebar */}
      <div className="w-16 bg-[#121212] border-r border-[#1f1f1f] flex flex-col items-center py-4 space-y-6">
        <div className="text-2xl cursor-pointer hover:bg-[#1f1f1f] p-2 rounded transition">🏠</div>
        <div className="text-2xl cursor-pointer hover:bg-[#1f1f1f] p-2 rounded transition">💻</div>
        <div className="text-2xl cursor-pointer hover:bg-[#1f1f1f] p-2 rounded transition">🌐</div>
        <div className="text-2xl cursor-pointer hover:bg-[#1f1f1f] p-2 rounded transition">👤</div>
        <div className="text-2xl cursor-pointer hover:bg-[#1f1f1f] p-2 rounded transition">⭐</div>
        <div className="text-2xl cursor-pointer hover:bg-[#1f1f1f] p-2 rounded transition">⚙️</div>
      </div>

      {/* Main Content */}
      <div className="flex-1 flex flex-col">
        {/* Header Profile Card */}
        <div className="bg-[#121212] border-b border-[#1f1f1f] p-6 shadow-lg">
          <div className="flex items-center space-x-4">
            <div className="w-16 h-16 bg-[#1f1f1f] rounded-full flex items-center justify-center text-2xl">👤</div>
            <div>
              <h1 className="text-3xl font-bold">Hello, RonixHub_Owner</h1>
              <p className="text-[#888888] text-lg">Medusa v15.1 - Universal Script</p>
            </div>
          </div>
        </div>

        {/* Grid of Cards */}
        <div className="flex-1 p-6 grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6">
          {/* Server Card */}
          <div className="bg-[#121212] border border-[#1f1f1f] rounded-lg p-6 hover:shadow-lg transition-shadow">
            <h2 className="text-xl font-semibold mb-4">Server</h2>
            <div className="space-y-3">
              <div className="flex justify-between items-center">
                <span className="text-[#888888]">Players:</span>
                <span className="text-[#00ff87] font-bold text-lg" style={{textShadow: '0 0 10px #00ff87'}}>12/20</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-[#888888]">Latency:</span>
                <span className="text-[#00ff87] font-bold text-lg" style={{textShadow: '0 0 10px #00ff87'}}>45ms</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-[#888888]">Region:</span>
                <span className="text-[#00ff87] font-bold text-lg" style={{textShadow: '0 0 10px #00ff87'}}>US East</span>
              </div>
            </div>
          </div>

          {/* Wave Card - Executor Status */}
          <div className="bg-gradient-to-r from-[#00ff87] to-[#00a34c] rounded-lg p-6 hover:shadow-lg transition-shadow col-span-1 md:col-span-2 xl:col-span-2">
            <h2 className="text-xl font-semibold mb-4 text-black">Executor Status</h2>
            <p className="text-black text-lg font-medium">System Check: Running</p>
          </div>

          {/* Friends Card */}
          <div className="bg-[#121212] border border-[#1f1f1f] rounded-lg p-6 hover:shadow-lg transition-shadow">
            <h2 className="text-xl font-semibold mb-4">Friends</h2>
            <div className="space-y-3">
              <div className="flex justify-between items-center">
                <span className="text-[#888888]">Online:</span>
                <span className="text-[#00ff87] font-bold text-lg" style={{textShadow: '0 0 10px #00ff87'}}>5</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-[#888888]">Offline:</span>
                <span className="text-[#71717a] font-bold text-lg">3</span>
              </div>
            </div>
          </div>

          {/* Discord Card */}
          <div className="bg-gradient-to-r from-[#00ff87] to-[#00a34c] rounded-lg p-6 hover:shadow-lg transition-shadow col-span-1 md:col-span-2 xl:col-span-2">
            <h2 className="text-xl font-semibold mb-4 text-black">Join Discord</h2>
            <p className="text-black text-lg font-medium">JOIN THE DISCORD SERVER</p>
          </div>
        </div>
      </div>
    </div>
  );
}

export default App;